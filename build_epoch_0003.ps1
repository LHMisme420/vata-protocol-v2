# ============================================================
# build_epoch_0003.ps1
# Builds Merkle tree from ./claims
# Saves ./epoch_0003/proofs.json
# Anchors root on Optimism Sepolia as EPOCH = 3
# ============================================================

Set-StrictMode -Version Latest
. .\merkle_tools.ps1

$EPOCH    = 3
$CLAIMS   = ".\claims"
$OUTDIR   = ".\epoch_0003"

$RPC = "https://sepolia.optimism.io"
$REG = "0xFf42b9605EE6C592A10805761F756197D3d500e4"

New-Item -ItemType Directory -Force -Path $OUTDIR | Out-Null

$files = Get-ChildItem $CLAIMS -File | Sort-Object Name
if ($files.Count -eq 0) { throw "No claim files found in $CLAIMS" }

Write-Host "Epoch=$EPOCH"
Write-Host "FileCount=$($files.Count)"

# leaf = keccak(file bytes) using PowerShell -> cast keccak
function LeafFromFile([string]$path) {
    $bytes = [System.IO.File]::ReadAllBytes($path)
    $hex = ($bytes | ForEach-Object { $_.ToString("x2") }) -join ''
    $out = & cast keccak ("0x" + $hex) 2>$null
    if (-not $out) { throw "cast keccak failed for $path" }
    return (Normalize-Hex $out)
}

$leaves = @()
$paths  = @()

foreach ($f in $files) {
    $leaves += (LeafFromFile $f.FullName)
    $paths  += $f.Name
}

# ---- build tree levels (hex nodes) ----
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

$proofs | ConvertTo-Json -Depth 10 | Set-Content "$OUTDIR\proofs.json" -Encoding utf8
Write-Host "Saved: $OUTDIR\proofs.json"

# ---- anchor root ----
Write-Host "Anchoring onchain (epoch $EPOCH)..."
$sendOut = & cast send `
  $REG `
  "anchorRoot(uint64,bytes32)" `
  $EPOCH `
  $root `
  --rpc-url $RPC `
  --private-key $env:PK `
  --gas-limit 500000 2>&1

$sendOut