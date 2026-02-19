param(
  [Parameter(Mandatory=$true)][string]$ClaimId,
  [Parameter(Mandatory=$true)][string]$RPC,
  [Parameter(Mandatory=$true)][string]$Token,
  [Parameter(Mandatory=$true)][string]$Registry
)

$dir = Join-Path ".\truth-ledger\claims" $ClaimId
$claimPath = Join-Path $dir "claim.json"
if (-not (Test-Path $claimPath)) { throw "Missing: $claimPath" }

$c = Get-Content $claimPath -Raw | ConvertFrom-Json

function Dec($hex) { (cast --to-dec $hex).Trim() }

Write-Host "Claim:" $c.claim_id
Write-Host "Domain:" $c.domain
Write-Host "Statement:" $c.statement
Write-Host ""

Write-Host "Stake TX:" $c.stake_tx
$stake = cast receipt $c.stake_tx --rpc-url $RPC
Write-Host $stake
Write-Host ""

Write-Host "Bond TX:" $c.bond_tx
$bond = cast receipt $c.bond_tx --rpc-url $RPC
Write-Host $bond
Write-Host ""

Write-Host "Payout TX:" $c.payout_tx
$payout = cast receipt $c.payout_tx --rpc-url $RPC
Write-Host $payout
Write-Host ""
Write-Host "Done."
