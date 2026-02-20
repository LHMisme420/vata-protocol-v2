# Contributing to the VATA Truth Ledger

## Submitting a Claim (PR)

1) Generate a canonical claim folder:
```bash
powershell -ExecutionPolicy Bypass -File tools/make_claim.ps1 `
  -Domain "ai.forensics" `
  -Statement "..." `
  -Claimant "0x..." `
  -EvidenceSha256 "0x..."
