# anchor_all_receipts.ps1 (Windows PowerShell 5.1)
# Batch anchor + claim generation for *_receipt.txt files (dedupes identical hashes)

[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string]$ReceiptDir,
  [Parameter(Mandatory=$true)][string]$OutClaimsDir,
  [Parameter(Mandatory=$true)][string]$AnchorAddress,
  [string]$RpcUrl = $env:RPC,
  [string]$PrivateKey = $env:PK,
  [string]$GasPrice = "",        # e.g. "0.05gwei" for OP
  [int]$StartIndex = 1,
  [switch]$VerifyOnchain
)

$ErrorActionPreference = "Stop"

function Fail([string]$m){ Write-Host ("[FAIL] " + $m) -ForegroundColor Red; exit 1 }
function Ok([string]$m){ Write-Host ("[OK]   " + $m) -ForegroundColor Green }
function Info([string]$m){ Write-Host ("[INFO] " + $m) -ForegroundColor Cyan }
function Warn([string]$m){ Write-Host ("[WARN] " + $m) -ForegroundColor Yellow }

function Normalize0x([string]$h){
  if($null -eq $h){ return "" }
  $h = $h.Trim()
  if($h -eq ""){ return "" }
  if($h.StartsWith("0x")){ return $h.ToLower() }
  return ("0x"+$h).ToLower()
}

function Require-Cast(){
  if(-not (Get-Command cast -ErrorAction SilentlyContinue)){ Fail "cast not found in PATH" }
}

function Sha2560xOfFile([string]$path){
  $bytes = [System.IO.File]::ReadAllBytes($path)
  $sha = [System.Security.Cryptography.SHA256]::Create().ComputeHash($bytes)
  $hex = ($sha | ForEach-Object { $_.ToString("x2") }) -join ""
  return ("0x" + $hex)
}

function WriteUtf8NoBom([string]$path,[string]$text){
  $dir = Split-Path -Parent $path
  if($dir -and -not (Test-Path $dir)){ New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  [System.IO.File]::WriteAllText($path, $text, (New-Object System.Text.UTF8Encoding($false)))
}

function NextClaimPath([int]$idx){
  return (Join-Path $OutClaimsDir ("claim_{0:D4}.json" -f $idx))
}

function ExtractTxHash([string]$text){
  $m = [regex]::Match($text, "0x[a-fA-F0-9]{64}")
  if($m.Success){ return $m.Value.ToLower() }
  return ""
}

# ---- preflight
Require-Cast
$ReceiptDir = (Resolve-Path $ReceiptDir).Path
if(-not (Test-Path $OutClaimsDir)){ New-Item -ItemType Directory -Force -Path $OutClaimsDir | Out-Null }
$OutClaimsDir = (Resolve-Path $OutClaimsDir).Path

$AnchorAddress = Normalize0x $AnchorAddress
if($AnchorAddress.Length -ne 42){ Fail "AnchorAddress is not a 20-byte 0x address" }

if(-not $RpcUrl -or $RpcUrl.Trim() -eq ""){ Fail "RpcUrl missing. Set -RpcUrl or env:RPC" }
if(-not $PrivateKey -or $PrivateKey.Trim() -eq ""){ Fail "Private key missing. Set -PrivateKey or env:PK" }

Info ("ReceiptDir   = " + $ReceiptDir)
Info ("OutClaimsDir = " + $OutClaimsDir)
Info ("Anchor       = " + $AnchorAddress)
Info ("RPC          = " + $RpcUrl)
Info ("StartIndex   = " + $StartIndex)
if($GasPrice -and $GasPrice.Trim() -ne ""){ Info ("GasPrice     = " + $GasPrice) }

# ---- collect receipts
$receipts = Get-ChildItem -Path $ReceiptDir -File -Filter "*_receipt.txt" | Sort-Object Name
if(-not $receipts -or $receipts.Count -eq 0){ Fail "No *_receipt.txt files found in ReceiptDir" }

Info ("Found receipts = " + $receipts.Count)

# ---- hash + dedupe
$byRoot = @{}   # root -> list of files
foreach($f in $receipts){
  $root = Sha2560xOfFile $f.FullName
  if(-not $byRoot.ContainsKey($root)){ $byRoot[$root] = New-Object System.Collections.ArrayList }
  [void]$byRoot[$root].Add($f.FullName)
  Info ("hash " + $f.Name + " => " + $root)
}

$uniqueRoots = $byRoot.Keys | Sort-Object
Info ("Unique roots (after dedupe) = " + $uniqueRoots.Count)

# ---- anchor each unique root + write claim(s)
$z32="0x0000000000000000000000000000000000000000000000000000000000000000"
$idx = $StartIndex

foreach($root in $uniqueRoots){
  $ts64 = [uint64][double]::Parse((Get-Date -UFormat %s))

  Info ("Anchoring root " + $root)

  $args = @(
    "send", $AnchorAddress,
    "anchor(bytes32,uint64,bytes32,bytes32)",
    $root, $ts64, $z32, $z32,
    "--rpc-url", $RpcUrl,
    "--private-key", $PrivateKey
  )
  if($GasPrice -and $GasPrice.Trim() -ne ""){ $args += @("--gas-price", $GasPrice.Trim()) }

  $sendOut = (& cast @args 2>&1 | Out-String)
  $tx = ExtractTxHash $sendOut
  if($tx -eq ""){ Fail ("Could not extract tx hash from cast send output:`n" + $sendOut) }
  Ok ("tx = " + $tx)

  # Write one claim per receipt file (even if duplicates), all pointing to same root/tx
  $files = $byRoot[$root]
  foreach($path in $files){
    $claimPath = NextClaimPath $idx
    $epochId = ("epoch_{0:D4}" -f $idx)

    $claim = [ordered]@{
      schema="truth-ledger-claim-v1"
      created_at=(Get-Date).ToString("o")
      epoch_id=$epochId
      root=$root
      receipt_path=$path
      receipt_sha256=$root
      onchain=[ordered]@{
        chain_id=0
        anchor_address=$AnchorAddress
        tx_hash=$tx
        method="anchor(bytes32,uint64,bytes32,bytes32)"
      }
    }

    $json = $claim | ConvertTo-Json
    WriteUtf8NoBom $claimPath $json
    Ok ("Wrote " + $claimPath + "  (" + (Split-Path -Leaf $path) + ")")
    $idx++
  }

  if($VerifyOnchain){
    $verify = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "verify_ledger.ps1"
    if(-not (Test-Path $verify)){ Warn "verify_ledger.ps1 not found next to this script; skipping verify"; continue }
    $firstClaimForRoot = NextClaimPath ($idx - $files.Count)
    Info ("Verifying " + $firstClaimForRoot)
    & $verify -ClaimPath $firstClaimForRoot -RpcUrl $RpcUrl -AnchorAddress $AnchorAddress -CheckOnchain
  }
}

Ok "Batch anchoring + claim generation complete."
