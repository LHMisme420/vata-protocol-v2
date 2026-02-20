
  # verify_ledger.ps1 (COMPLETE + UPDATED, Windows PowerShell 5.1 compatible)
# - Reads claim JSON safely
# - Validates receipt sha256
# - Optional on-chain verification via log scan (RPC max range safe: 50,000)

[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string]$ClaimPath,
  [string]$RpcUrl = $env:RPC,
  [string]$AnchorAddress = "",
  [switch]$CheckOnchain
)

$ErrorActionPreference = "Stop"
Write-Host "[INFO] verify_ledger.ps1 started" -ForegroundColor Cyan

function Fail([string]$m){ Write-Host ("[FAIL] " + $m) -ForegroundColor Red; exit 1 }
function Ok([string]$m){ Write-Host ("[OK]   " + $m) -ForegroundColor Green }
function Warn([string]$m){ Write-Host ("[WARN] " + $m) -ForegroundColor Yellow }
function Info([string]$m){ Write-Host ("[INFO] " + $m) -ForegroundColor Cyan }

function Normalize0x([string]$h){
  if($null -eq $h){ return "" }
  $h = $h.Trim()
  if($h -eq ""){ return "" }
  if($h.StartsWith("0x")){ return $h.ToLower() }
  return ("0x"+$h).ToLower()
}

function Read-JsonSafe([string]$path){
  if(-not (Test-Path $path)){ Fail ("Missing claim file: " + $path) }

  $raw = Get-Content $path -Raw
  $raw = $raw -replace "^\uFEFF",""
  $raw = $raw.Trim()

  if($raw.Length -eq 0){ Fail ("Claim file is empty: " + $path) }

  if(-not ($raw.StartsWith("{") -or $raw.StartsWith("["))){
    $s = $raw.IndexOf("{")
    $e = $raw.LastIndexOf("}")
    if($s -ge 0 -and $e -gt $s){
      $raw = $raw.Substring($s, $e-$s+1).Trim()
    } else {
      Fail ("JSON must start with { or [: " + $path)
    }
  }

  try { return ($raw | ConvertFrom-Json) }
  catch { Fail ("ConvertFrom-Json failed: " + $_.Exception.Message) }
}

function Get-Field($obj,[string[]]$paths){
  foreach($p in $paths){
    $cur = $obj; $ok = $true
    foreach($seg in $p.Split(".")){
      if($null -eq $cur){ $ok=$false; break }
      if($cur.PSObject.Properties.Name -contains $seg){ $cur = $cur.$seg } else { $ok=$false; break }
    }
    if($ok -and $null -ne $cur -and (""+$cur).Trim() -ne ""){ return $cur }
  }
  return $null
}

function Sha2560xOfFile([string]$path){
  if(-not (Test-Path $path)){ Fail ("Missing receipt file: " + $path) }
  $bytes = [System.IO.File]::ReadAllBytes((Resolve-Path $path))
  $sha = [System.Security.Cryptography.SHA256]::Create()
  $hash = $sha.ComputeHash($bytes)
  $hex = ($hash | ForEach-Object { $_.ToString("x2") }) -join ""
  return ("0x" + $hex)
}

function Require-Cast(){
  $c = Get-Command cast -ErrorAction SilentlyContinue
  if(-not $c){ Fail "cast not found in PATH" }
}

# --- main ---
$ClaimPath = (Resolve-Path $ClaimPath).Path
Info ("ClaimPath = " + $ClaimPath)

$claim = Read-JsonSafe $ClaimPath

$rootRaw = Get-Field $claim @("root","merkle_root","merkleRoot","ledger.root","truth_ledger.root","bundle.root","anchor.root")
$receiptPath = Get-Field $claim @("receipt_path","receiptPath","files.receipt","bundle.receipt","paths.receipt")
$receiptSha  = Get-Field $claim @("receipt_sha256","receiptSha256","sha256_receipt","hashes.receipt_sha256","hashes.receipt","receipt.hash.sha256")

$root0x = Normalize0x (""+$rootRaw)
$receiptSha0x = Normalize0x (""+$receiptSha)

Info ("root          = " + ($(if($root0x){$root0x}else{"<missing>"})))
Info ("receipt_path  = " + ($(if($receiptPath){$receiptPath}else{"<missing>"})))
Info ("receipt_sha256= " + ($(if($receiptSha0x){$receiptSha0x}else{"<missing>"})))

if($receiptPath){
  if(-not [System.IO.Path]::IsPathRooted($receiptPath)){
    $receiptPath = Join-Path (Split-Path -Parent $ClaimPath) $receiptPath
  }
}

if($receiptPath){
  $fileSha = Sha2560xOfFile $receiptPath
  Info ("sha256(receipt file) = " + $fileSha)

  if($receiptSha0x){
    if($fileSha.ToLower() -ne $receiptSha0x.ToLower()){
      Fail ("receipt sha mismatch`n claim: " + $receiptSha0x + "`n file : " + $fileSha)
    } else {
      Ok "receipt sha matches claim"
    }
  } else {
    Warn "claim missing receipt_sha256"
  }
} else {
  Warn "claim missing receipt_path; skipping receipt check"
}

# Optional on-chain check (RPC max range safe)
if($CheckOnchain){
  if(-not $AnchorAddress -or $AnchorAddress.Trim() -eq ""){ Fail "AnchorAddress missing" }
  if(-not $root0x){ Fail "root missing in claim" }

  Require-Cast
  $AnchorAddress = Normalize0x $AnchorAddress

  if(-not $RpcUrl -or $RpcUrl.Trim() -eq ""){ Fail "RpcUrl missing. Set -RpcUrl or env:RPC" }

  Info "Onchain check: scanning logs for this root (RPC max range safe)"

  $latest = (& cast block-number --rpc-url $RpcUrl 2>&1 | Out-String).Trim()
  if($latest -match "Error:"){ Fail ("cast block-number failed: " + $latest) }

  $toBlock = [int]$latest
  $chunk = 10000   # RPC limit (OP often needs <=10k)

  $maxScan = 300000 # how far back total (adjust if needed)

  $rootWord = $root0x.ToLower()
  $rootNo0x = $rootWord.Replace("0x","")

  $found = $false
  $scanned = 0
  while($scanned -lt $maxScan -and -not $found){
    $fromBlock = $toBlock - $chunk + 1
    if($fromBlock -lt 0){ $fromBlock = 0 }

    Info ("Scanning blocks " + $fromBlock + " .. " + $toBlock)

    $logs = (& cast logs --from-block $fromBlock --to-block $toBlock --address $AnchorAddress --rpc-url $RpcUrl 2>&1 | Out-String)
    if($logs -match "exceed maximum block range"){ Fail "RPC block-range limit hit (unexpected). Lower chunk below 50000." }
    if($logs -match "Error:"){ Fail ("cast logs failed: " + $logs) }

    $txt = $logs.ToLower()
    if($txt.Contains($rootWord) -or $txt.Contains($rootNo0x)){
      $found = $true
      break
    }

    $toBlock = $fromBlock - 1
    $scanned += $chunk
    if($toBlock -le 0){ break }
  }

  if($found){
    Ok "Found root in logs for anchor contract (anchored on-chain)"
  } else {
    Warn ("Did NOT find root in last ~" + $maxScan + " blocks. If anchored earlier, increase maxScan.")
  }
}

Ok "Verifier completed"
exit 0
