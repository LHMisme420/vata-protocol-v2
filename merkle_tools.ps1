# ============================================================
# merkle_tools.ps1
# Canonical Sorted-Pair Merkle Tree (HEX ONLY)
# Uses Foundry: cast keccak
# ============================================================

Set-StrictMode -Version Latest

function Normalize-Hex([string]$h) {
    if ([string]::IsNullOrWhiteSpace($h)) { throw "Null hex" }
    $h = $h.Trim()
    if ($h.StartsWith("0x")) { $h = $h.Substring(2) }
    return "0x$($h.ToLower())"
}

function HashConcat([string]$aHex, [string]$bHex) {
    $a = (Normalize-Hex $aHex).Substring(2)
    $b = (Normalize-Hex $bHex).Substring(2)

    $out = & cast keccak ("0x" + $a + $b) 2>$null
    if (-not $out) { throw "cast keccak failed" }

    return (Normalize-Hex $out)
}

# hash(min(a,b)||max(a,b))
function HashPair([string]$aHex, [string]$bHex) {
    $a = Normalize-Hex $aHex
    $b = Normalize-Hex $bHex
    if ($a -le $b) { return (HashConcat $a $b) }
    else           { return (HashConcat $b $a) }
}

function BuildMerkleRoot([string[]]$leaves) {
    if ($leaves.Count -eq 0) { throw "No leaves" }
    if ($leaves.Count -eq 1) { return (Normalize-Hex $leaves[0]) }

    $level = @()
    foreach ($l in $leaves) { $level += (Normalize-Hex $l) }

    while ($level.Count -gt 1) {
        $next = @()
        for ($i=0; $i -lt $level.Count; $i+=2) {
            if ($i+1 -ge $level.Count) { $next += $level[$i] }
            else { $next += (HashPair $level[$i] $level[$i+1]) }
        }
        $level = $next
    }
    return $level[0]
}

function VerifyMerkleProof([string]$leaf, $proofArr, [string]$root) {
    $current = Normalize-Hex $leaf
    $root    = Normalize-Hex $root

    $proofs = @()
    foreach ($p in @($proofArr)) {
        if ($p) { $proofs += (Normalize-Hex $p.ToString()) }
    }

    if ($proofs.Count -eq 0) { return $current -eq $root }

    foreach ($p in $proofs) { $current = HashPair $current $p }

    return $current -eq $root
}