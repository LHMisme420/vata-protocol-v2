$ErrorActionPreference = "Stop"

function CanonicalPreimage($c) {
  $domain   = ($c.domain   ?? "").ToString().Trim()
  $statement= ($c.statement?? "").ToString().Trim()
  $evidence = ($c.evidence_sha256 ?? "").ToString().Trim().ToLower()
  if ($evidence -eq "0x") { $evidence = "" }

  $claimant = ($c.claimant ?? "").ToString().Trim().ToLower()
  $ts       = ($c.timestamp_utc ?? "").ToString().Trim()

  @(
    "VATA-CLAIM|v1"
    "domain=$domain"
    "statement=$statement"
    "evidence_sha256=$evidence"
    "claimant=$claimant"
    "timestamp_utc=$ts"
  ) -join "`n"
}

$claimsRoot = Join-Path $PSScriptRoot "claims"
if (-not (Test-Path $claimsRoot)) { throw "Missing claims root: $claimsRoot" }

$folders = Get-ChildItem $claimsRoot -Directory
if ($folders.Count -eq 0) { throw "No claim folders found under $claimsRoot" }

$fail = $false

foreach ($f in $folders) {
  $claimPath = Join-Path $f.FullName "claim.json"
  if (-not (Test-Path $claimPath)) {
    Write-Host "FAIL: Missing claim.json in $($f.Name)"
    $fail = $true
    continue
  }

  $c = Get-Content $claimPath -Raw | ConvertFrom-Json

  $preimage = CanonicalPreimage $c
  $computed = (cast keccak $preimage).Trim().ToLower()

  $declared = (($c.claim_id ?? "")).ToString().Trim().ToLower()
  $folderId = $f.Name.Trim().ToLower()

  if ($declared -ne $computed) {
    Write-Host "FAIL: claim_id mismatch in $($f.Name)"
    Write-Host "  declared: $declared"
    Write-Host "  computed: $computed"
    $fail = $true
  }

  if ($folderId -ne $computed) {
    Write-Host "FAIL: folder name mismatch in $($f.Name)"
    Write-Host "  folder:   $folderId"
    Write-Host "  computed: $computed"
    $fail = $true
  } else {
    Write-Host "OK: $($f.Name)"
  }
}

if ($fail) { exit 1 }
Write-Host "All claims verified."
