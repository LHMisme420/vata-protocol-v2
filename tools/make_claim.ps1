param(
  [Parameter(Mandatory=$true)][string]$Domain,
  [Parameter(Mandatory=$true)][string]$Statement,
  [Parameter(Mandatory=$true)][string]$Claimant,
  [string]$EvidenceSha256 = ""
)

function NormalizeHex([string]$x) {
  if (-not $x) { return "" }
  $t = $x.Trim().ToLower()
  if ($t -eq "0x") { return "" }
  return $t
}

function NormalizeAddr([string]$a) {
  $t = $a.Trim().ToLower()
  if ($t.Length -ne 42 -or -not $t.StartsWith("0x")) { throw "Invalid address: $a" }
  return $t
}

$domain = $Domain.Trim()
$statement = $Statement.Trim()
$claimant = NormalizeAddr $Claimant
$evidence = NormalizeHex $EvidenceSha256

$ts = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

# Canonical preimage (MUST match VATA-CLAIM.md exactly)
$preimage = @(
  "VATA-CLAIM|v1"
  "domain=$domain"
  "statement=$statement"
  "evidence_sha256=$evidence"
  "claimant=$claimant"
  "timestamp_utc=$ts"
) -join "`n"

# Deterministic Claim ID
$claimId = (cast keccak $preimage).Trim()

# Folder path
$dir = Join-Path ".\truth-ledger\claims" $claimId
New-Item -ItemType Directory -Force -Path $dir | Out-Null

# claim.json
$claimObj = [ordered]@{
  vata_claim_version = "1.0"
  domain            = $domain
  statement         = $statement
  evidence_sha256   = $evidence
  claimant          = $claimant
  timestamp_utc     = $ts
  claim_id          = $claimId
}

($claimObj | ConvertTo-Json -Depth 10) | Set-Content (Join-Path $dir "claim.json") -Encoding UTF8

# Receipt placeholders (filled once on-chain activity exists)
"TODO: paste cast receipt <stake_tx> output here"  | Set-Content (Join-Path $dir "stake_receipt.txt")  -Encoding UTF8
"TODO: paste cast receipt <bond_tx> output here"   | Set-Content (Join-Path $dir "bond_receipt.txt")   -Encoding UTF8
"TODO: paste cast receipt <payout_tx> output here" | Set-Content (Join-Path $dir "payout_receipt.txt") -Encoding UTF8

Write-Host ""
Write-Host "CLAIM CREATED"
Write-Host "Claim ID: $claimId"
Write-Host "Folder:   $dir"
Write-Host ""
Write-Host "Preimage:"
Write-Host $preimage
Write-Host ""
