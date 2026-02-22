# ============================================================
# verify_epoch_0003.ps1
# Verifies every proof in ./epoch_0003/proofs.json vs onchain rootByEpoch(3)
# ============================================================

Set-StrictMode -Version Latest
. .\merkle_tools.ps1

$RPC   = "https://sepolia.optimism.io"
$REG   = "0xFf42b9605EE6C592A10805761F756197D3d500e4"
$EPOCH = 3

Write-Host "Loading onchain root..."
$root = & cast call $REG "rootByEpoch(uint64)(bytes32)" $EPOCH --rpc-url $RPC
$root = Normalize-Hex $root
Write-Host "ROOT = $root"
Write-Host ""

$proofs = Get-Content ".\epoch_0003\proofs.json" -Raw | ConvertFrom-Json

$pass = 0
$fail = 0

foreach ($p in $proofs) {
    $ok = VerifyMerkleProof $p.leaf ($p.proof | ForEach-Object { "$_" }) $root
    if ($ok) { Write-Host "[PASS] $($p.path)"; $pass++ }
    else     { Write-Host "[FAIL] $($p.path)"; $fail++ }
}

Write-Host ""
Write-Host "SUMMARY:"
Write-Host "PASS = $pass"
Write-Host "FAIL = $fail"