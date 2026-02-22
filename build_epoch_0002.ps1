# ============================================================
# build_epoch_0002.ps1
# Builds Merkle tree from ./claims
# Saves proofs.json
# Anchors root on Optimism Sepolia
# ============================================================

Set-StrictMode -Version Latest
. .\merkle_tools.ps1

$EPOCH    = 2
$CLAIMS   = ".\claims"
$OUTDIR   = ".\epoch_0002"

$RPC = "https://sepolia.optimism.io"
$REG = "0xFf42b9605EE6C592A10805761F756197D3d500e4"

New-Item -ItemType Directory -Force -Path $OUTDIR | Out-Null

$files = Get-ChildItem $CLAIMS -File | Sort-Object Name
if ($files.Count -eq 0) { throw "No claim files found" }

Write-Host "Epoch=$EPOCH"
Write-Host "FileCount=$($files.Count)"

# ---- keccak(file bytes) using PowerShell -> cast keccak ----
function LeafFromFile($path) {

    # Read bytes
    $bytes = [System.IO.File]::ReadAllBytes($path)

    # Convert to hex
    $hex = ($bytes | ForEach-Object { $_.ToString("x2") }) -join ''
    $hex = "0x$hex"

    $out = & cast keccak $hex 2>$null
    if (-not $out) { throw "cast keccak failed for $path" }

    return (Normalize-Hex $out)
}

$leaves = @()
$paths  = @()

foreach ($f in $files) {
    $leaves += (LeafFromFile $f.FullName)
    $paths  += $f.Name
}

# ---- build tree levels ----
$levels = @()
$levels += ,$leaves

while ($levels[-1].Count -gt 1) {

    $cur = $levels[-1]
    $nxt = @()

    for ($i=0; $i -lt $cur.Count; $i+=2) {
        if ($i+1 -ge $cur.Count) {
            $nxt += $cur[$i]
        } else {
            $nxt += (HashPair $cur[$i] $cur[$i+1])
        }
    }

    $levels += ,$nxt
}

$root = $levels[-1][0]
Write-Host "MerkleRoot=$root"

# ---- build proofs ----
$proofs = @()

for ($i=0; $i -lt $leaves.Count; $i++) {

    $pos = $i
    $p = @()

    for ($lvl=0; $lvl -lt ($levels.Count-1); $lvl++) {

        $cur = $levels[$lvl]
        $sib = if ($pos % 2 -eq 0) { $pos+1 } else { $pos-1 }

        if ($sib -lt $cur.Count) {
            $p += $cur[$sib]
        }

        $pos = [math]::Floor($pos/2)
    }

    $proofs += [pscustomobject]@{
        path  = $paths[$i]
        leaf  = $leaves[$i]
        proof = $p
    }
}

$proofs | ConvertTo-Json -Depth 10 | Set-Content "$OUTDIR\proofs.json"
Write-Host "Saved: $OUTDIR\proofs.json"

# ---- anchor root ----
$URI = "https://github.com/LHMisme420/vata-protocol-v2"

Write-Host "Anchoring onchain..."
$tx = & cast send `
  $REG `
  "anchor(uint64,bytes32,string)" `
  $EPOCH `
  $root `
  $URI `
  --rpc-url $RPC `
  --private-key $env:PK 2>$null

$tx