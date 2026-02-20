[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string]$ReceiptPath,
  [string]$OutClaimPath = ".\claims\claim_0002.json",
  [string]$EpochId = "epoch_0002",
  [string]$Chain = "",
  [string]$RpcUrl = "",
  [string]$AnchorAddress = "",
  [string]$TxHash = ""
)

function Fail([string]$m){ Write-Host ("[FAIL] " + $m) -ForegroundColor Red; exit 1 }
function Ok([string]$m){ Write-Host ("[OK]   " + $m) -ForegroundColor Green }
function Info([string]$m){ Write-Host ("[INFO] " + $m) -ForegroundColor Cyan }

function Normalize0x([string]$h){
  if($null -eq $h){ return "" }
  $h = $h.Trim()
  if($h -eq ""){ return "" }
  if($h.StartsWith("0x")){ return $h.ToLower() }
  return ("0x"+$h).ToLower()
}

function Sha256HexOfFile([string]$path){
  if(-not (Test-Path $path)){ Fail ("Missing file: " + $path) }
  $bytes = [System.IO.File]::ReadAllBytes((Resolve-Path $path))
  $sha = [System.Security.Cryptography.SHA256]::Create()
  $hash = $sha.ComputeHash($bytes)
  ($hash | ForEach-Object { $_.ToString("x2") }) -join ""
}

function WriteUtf8NoBom([string]$path,[string]$text){
  $full = $path
  if(-not [System.IO.Path]::IsPathRooted($full)){
    $full = Join-Path (Get-Location) $full
  }
  $dir = Split-Path -Parent $full
  if($dir -and -not (Test-Path $dir)){ New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  [System.IO.File]::WriteAllText($full, $text, (New-Object System.Text.UTF8Encoding($false)))
}

# --- main ---
$ReceiptPath = (Resolve-Path $ReceiptPath).Path

Info ("ReceiptPath = " + $ReceiptPath)
$shaHex = Sha256HexOfFile $ReceiptPath
$sha0x  = "0x$shaHex"
Ok ("SHA256(receipt) = " + $sha0x)

$now = (Get-Date).ToString("o")
$claim = [ordered]@{
  schema         = "truth-ledger-claim-v1"
  created_at     = $now
  epoch_id       = $EpochId
  root           = $sha0x
  receipt_path   = $ReceiptPath
  receipt_sha256 = $sha0x
  onchain = [ordered]@{
    chain          = $Chain
    rpc_url        = $RpcUrl
    anchor_address = (Normalize0x $AnchorAddress)
    tx_hash        = (Normalize0x $TxHash)
  }
}

if(($claim.onchain.chain -eq "") -and ($claim.onchain.rpc_url -eq "") -and
   ($claim.onchain.anchor_address -eq "") -and ($claim.onchain.tx_hash -eq "")){
  $claim.Remove("onchain")
}

$json = $claim | ConvertTo-Json -Depth 50
WriteUtf8NoBom $OutClaimPath $json
Ok ("Wrote claim: " + (Resolve-Path $OutClaimPath))
