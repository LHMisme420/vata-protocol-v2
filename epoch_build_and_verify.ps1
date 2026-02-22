# ============================================================
# epoch_build_and_verify.ps1
# One-shot: build proofs, compute local root, attempt anchor with multiple sigs,
# confirm onchain root, verify proofs vs LOCAL and ONCHAIN.
#
# Usage:
#   .\epoch_build_and_verify.ps1 -Epoch 3
# ============================================================

param(
  [Parameter(Mandatory=$true)]
  [int]$Epoch
)

Set-StrictMode -Version Latest
. .\merkle_tools.ps1

$CLAIMS = ".\claims"
$OUTDIR = ".\epoch_{0:d4}" -f $Epoch

$RPC = "https://sepolia.optimism.io"
$REG = "0xFf42b9605EE6C592A10805761F756197D3d500e4"

if (-not $env:PK -or $env:PK.Trim().Length -lt 64) {
  throw "Missing env:PK (need 64-hex private key, no 0x). Set `$env:PK then rerun."
}

New-Item -ItemType Directory -Force -Path $OUTDIR | Out-Null

$files = Get-ChildItem $CLAIMS -File | Sort-Object Name
if ($files.Count -eq 0) { throw "No claim files found in $CLAIMS" }

Write-Host "Epoch=$Epoch"
Write-Host "Claims=$CLAIMS"
Write-Host "FileCount=$($files.Count)"
Write-Host ""

function LeafFromFile([string]$path) {
    $bytes = [System.IO.File]::ReadAllBytes($path)
    $hex = ($bytes | ForEach-Object { $_.ToString("x2") }) -join ''
    $out = & cast keccak ("0x" + $hex) 2>$null
    if (-not $out) { throw "cast keccak failed for $path" }
    return (Normalize-Hex $out)
}

# Leaves in filename order
$leaves = @()
$paths  = @()
foreach ($f in $files) {
  $leaves += (LeafFromFile $f.FullName)
  $paths  += $f.Name
}

# Build levels (hex nodes)
$levels = @()
$levels += ,$leaves
while ($levels[-1].Count -gt 1) {
  $cur = $levels[-1]
  $nxt = @()
  for ($i=0; $i -lt $cur.Count; $i+=2) {
    if ($i+1 -ge $cur.Count) { $nxt += $cur[$i] }
    else { $nxt += (HashPair $cur[$i] $cur[$i+1]) }
  }
  $levels += ,$nxt
}

$localRoot = $levels[-1][0]
Write-Host "LOCAL_ROOT=$localRoot"

# Build proofs
$proofs = @()
for ($i=0; $i -lt $leaves.Count; $i++) {
  $pos = $i
  $p = @()
  for ($lvl=0; $lvl -lt ($levels.Count-1); $lvl++) {
    $cur = $levels[$lvl]
    $sib = if ($pos % 2 -eq 0) { $pos + 1 } else { $pos - 1 }
    if ($sib -lt $cur.Count) { $p += $cur[$sib] }
    $pos = [math]::Floor($pos / 2)
  }
  $proofs += [pscustomobject]@{ path=$paths[$i]; leaf=$leaves[$i]; proof=$p }
}

$proofPath = Join-Path $OUTDIR "proofs.json"
$proofs | ConvertTo-Json -Depth 10 | Set-Content $proofPath -Encoding utf8
Write-Host "Saved=$proofPath"
Write-Host ""

# ---- verify vs LOCAL root first (this isolates merkle correctness) ----
$passLocal=0; $failLocal=0
foreach ($e in $proofs) {
  $ok = VerifyMerkleProof $e.leaf ($e.proof | ForEach-Object { "$_" }) $localRoot
  if ($ok) { $passLocal++ } else { $failLocal++ }
}
Write-Host "LOCAL_VERIFY: PASS=$passLocal FAIL=$failLocal"
if ($failLocal -ne 0) {
  Write-Host "STOP: Proofs do not match LOCAL root. Builder logic mismatch." -ForegroundColor Red
  exit 1
}
Write-Host "LOCAL_VERIFY: OK ✅"
Write-Host ""

# ---- Helper: fetch onchain root with possible epoch type variants ----
function GetOnchainRoot([int]$EpochNum) {
  $sigs = @(
    "rootByEpoch(uint64)(bytes32)",
    "rootByEpoch(uint256)(bytes32)"
  )
  foreach ($sig in $sigs) {
    $out = & cast call $REG $sig $EpochNum --rpc-url $RPC 2>$null
    if ($out -and $out.Trim().StartsWith("0x") -and $out.Trim().Length -eq 66) {
      return (Normalize-Hex $out.Trim())
    }
  }
  return $null
}

$before = GetOnchainRoot $Epoch
Write-Host "ONCHAIN_ROOT_BEFORE=$before"
Write-Host ""

# ---- Anchor: try likely function signatures (old cast, no ABI introspection) ----
$anchorSigs = @(
  "anchorRoot(uint64,bytes32)",
  "anchorRoot(uint256,bytes32)",
  "anchor(uint64,bytes32)",
  "anchor(uint256,bytes32)"
)

$txHash = $null
foreach ($fn in $anchorSigs) {

  Write-Host "Trying: $fn" -ForegroundColor Cyan

  $out = & cast send `
    $REG `
    $fn `
    $Epoch `
    $localRoot `
    --rpc-url $RPC `
    --private-key $env:PK `
    --gas-limit 500000 2>&1

  $out | Write-Host

  # attempt to extract tx hash from output
  $m = [regex]::Match($out, "0x[a-fA-F0-9]{64}")
  if ($m.Success) {
    $txHash = $m.Value
    Write-Host "TX=$txHash" -ForegroundColor Green
    break
  }

  Write-Host "No tx hash parsed for $fn, trying next..." -ForegroundColor Yellow
  Write-Host ""
}

if (-not $txHash) {
  Write-Host "STOP: Could not send an anchor tx with any known signature." -ForegroundColor Red
  exit 1
}

# Check receipt status
$rcpt = & cast receipt $txHash --rpc-url $RPC 2>&1
$rcpt | Write-Host
if ($rcpt -match "status\s+0") {
  Write-Host "STOP: Anchor tx reverted. The signature matched a function selector but the call failed (likely: epoch locked / auth / already set)." -ForegroundColor Red
  exit 1
}

# Confirm onchain root changed
$after = GetOnchainRoot $Epoch
Write-Host ""
Write-Host "ONCHAIN_ROOT_AFTER=$after"
Write-Host ""

if ($after -ne $localRoot) {
  Write-Host "STOP: Onchain root does not match LOCAL root. Anchor did not set root for this epoch." -ForegroundColor Red
  exit 1
}

Write-Host "ONCHAIN_ROOT matches LOCAL_ROOT ✅" -ForegroundColor Green
Write-Host ""

# ---- Verify vs ONCHAIN root ----
$pass=0; $fail=0
foreach ($e in $proofs) {
  $ok = VerifyMerkleProof $e.leaf ($e.proof | ForEach-Object { "$_" }) $after
  if ($ok) { Write-Host "[PASS] $($e.path)"; $pass++ } else { Write-Host "[FAIL] $($e.path)"; $fail++ }
}

Write-Host ""
Write-Host "SUMMARY: PASS=$pass FAIL=$fail"
if ($fail -eq 0) { Write-Host "ALL GOOD ✅" -ForegroundColor Green }