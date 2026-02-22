param(
    [Parameter(Mandatory=$true)]
    [string]$Root,

    [switch]$DryRun
)

if (-not ($Root -match "^0x[0-9a-fA-F]{64}$")) {
    Write-Host "ERROR: Invalid root format"
    exit 1
}

$networks = Get-Content "..\config\networks.json" | ConvertFrom-Json

foreach ($n in $networks.PSObject.Properties) {

    $rpc = $n.Value.rpc
    $reg = $n.Value.registry

    Write-Host "=============================="
    Write-Host "Network : $($n.Name)"
    Write-Host "Registry: $reg"
    Write-Host "Root    : $Root"
    Write-Host "=============================="

    if (-not $DryRun) {
        cast send $reg "anchorRoot(uint256)" $Root `
            --rpc-url $rpc `
            --private-key $env:PK
    }

    $ok = cast call $reg "isRoot(uint256)" $Root --rpc-url $rpc

    Write-Host "Verified: $ok"
    Write-Host ""
}