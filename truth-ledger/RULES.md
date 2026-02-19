# VATA Truth Settlement Rules (v1)

VATA is a Truth Settlement Layer.

A claim becomes economically meaningful only when bonded.

## Claim Lifecycle

1. Claim Submission
- Claimant posts a statement.
- Claimant stakes VATA.
- Claim ID = deterministic hash of claim object.

2. Challenge Window
- Anyone may challenge by bonding VATA.
- Challenge must reference the same Claim ID.

3. Resolution
- If challenger prevails → claimant pays.
- If no successful challenge → claim stands.
- Economic settlement is final.

## Economic Principles

- All claims require stake.
- All challenges require bond.
- Resolution is enforced on-chain.
- History is immutable.
- Flags are never erased.

Ethereum settles value.
VATA settles truth.
