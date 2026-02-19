# VATA Protocol Architecture

VATA is a Truth Settlement Layer (TSL) — a blockchain-native system for economically settling contested factual claims.

Ethereum settles value.  
VATA settles truth.

---

## 1. Layered Design

VATA is designed as a multi-layer system:

- Execution Layers (L2): Optimism, Arbitrum
- Settlement Layer (L1): Ethereum
- Data Layer: Truth Ledger (GitHub + IPFS compatible)
- Client Layer: CLI / scripts / verifiers

This separation enables scalability, low cost interaction, and high-finality settlement.

---

## 2. Execution Layers (Optimism / Arbitrum)

Responsibilities:

- Accept claim submissions
- Accept bonded challenges
- Enforce staking and bonding rules
- Emit claim and challenge events

Properties:

- Cheap transactions
- High throughput
- Fast confirmation

These layers handle the majority of protocol activity.

---

## 3. Settlement Layer (Ethereum L1)

Responsibilities:

- Final economic settlement
- Payout enforcement
- Canonical state anchoring
- Long-term permanence

Ethereum is treated as the source of truth for final outcomes.

---

## 4. Truth Ledger

The Truth Ledger is a public, append-only index of economically settled claims.

Each entry links to:

- claim.json
- stake receipt
- bond receipt
- payout receipt

The ledger itself is not a database.

It is a reproducible view over on-chain facts.

---

## 5. Claim Identity

Claim ID = deterministic hash of canonical claim object.

This ensures:

- Content-addressed claims
- Cross-chain portability
- Immutable identity

Claims are referenced by ID across all layers.

---

## 6. Economic Security Model

Security derives from:

- Claimant stake
- Challenger bond
- Slashing / payout enforcement
- Open adversarial participation

No trusted moderators exist.

Only incentives and cryptography.

---

## 7. Design Philosophy

- Truth is not voted on.
- Truth is not moderated.
- Truth is economically settled.

VATA does not decide what is true.

VATA decides who pays when claims are wrong.

---

## 8. Future Extensions

- ZK proof integration for private evidence
- Merkle inclusion proofs for large evidence sets
- Cross-chain claim mirroring
- Decentralized indexing of Truth Ledger

---

End of document.
