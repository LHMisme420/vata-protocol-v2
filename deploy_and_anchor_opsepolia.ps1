# ===== VATA AnchorRegistry Deploy + Anchor (OP Sepolia) =====


$env:PK ="c37c7189f1462151cb089520cd10a13e02cc013e01a6f5d8f138eae679ccf837"
$env:ETH_RPC_URL = "https://sepolia.optimism.io"
# 1) FORCE RPC FOR FORGE (avoids localhost)
$env:ETH_RPC_URL = "https://sepolia.optimism.io"
Write-Host "Using RPC:" $env:ETH_RPC_URL

# Validate PK quickly
if (-not $env:PK -or $env:PK.Trim().Length -ne 64) { throw "PK must be 64 hex chars (no 0x)." }

# 2) Compute deployer
$ADDR = cast wallet address --private-key $env:PK
Write-Host "DEPLOYER:" $ADDR

# 3) Build (stop on compile errors)
forge clean | Out-Null
forge build

# 4) Deploy (capture output)
$deployOut = forge create src/AnchorRegistry.sol:AnchorRegistry `
  --constructor-args $ADDR `
  --private-key $env:PK `
  --broadcast 2>&1 | Out-String

Write-Host $deployOut

$match = [regex]::Match($deployOut, "Deployed to:\s*(0x[a-fA-F0-9]{40})")
if (-not $match.Success) { throw "Deploy failed. Output:`n$deployOut" }

$REG = $match.Groups[1].Value
Write-Host "REGISTRY:" $REG

# 5) Make a manifest + anchor its hash
$EPOCH = 1

@"
{
  "project":"vata-protocol-v2",
  "epoch":$EPOCH,
  "timestamp":"$(Get-Date -Format o)",
  "note":"AnchorRegistry canonical root anchor on OP Sepolia"
}
"@ | Set-Content .\epoch-0001-manifest.json -Encoding utf8

$ROOT = "0x" + (Get-FileHash .\epoch-0001-manifest.json -Algorithm SHA256).Hash.ToLower()
$PAYLOAD = "0x0000000000000000000000000000000000000000000000000000000000000000"
$URI = ""

Write-Host "ROOT:" $ROOT

cast send $REG `
  "anchorRoot(uint64,bytes32,bytes32,string)" `
  $EPOCH $ROOT $PAYLOAD $URI `
  --rpc-url $env:ETH_RPC_URL `
  --private-key $env:PK

Write-Host "Verify isRoot(root):"
cast call $REG "isRoot(bytes32)(bool)" $ROOT --rpc-url $env:ETH_RPC_URL

Write-Host "Verify rootByEpoch(epoch):"
cast call $REG "rootByEpoch(uint64)(bytes32)" $EPOCH --rpc-url $env:ETH_RPC_URL

Write-Host "DONE ✅"
