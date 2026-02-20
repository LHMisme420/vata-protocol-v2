# VATA-CLAIM v1 (Canonical Claim Standard)

This document defines the canonical format for VATA Truth Ledger claims.

Goal: deterministic, portable claim identity.

---

## 1) Canonical Fields

A claim MUST define the following fields:

- vata_claim_version (string) = "1.0"
- domain (string) e.g. "ai.forensics"
- statement (string) human-readable claim
- evidence_sha256 (string) hex (0x...) optional but strongly recommended
- claimant (string) EVM address (0x...)
- timestamp_utc (string) ISO-8601 UTC (e.g. 2026-02-19T23:44:36Z)

Optional fields:
- metadata (object) any extra context (urls, notes)

---

## 2) Canonical Preimage (Claim ID)

The Claim ID is computed as:

claim_id = keccak256(preimage)

Where preimage is the UTF-8 bytes of:

VATA-CLAIM|v1
domain=<domain>
statement=<statement>
evidence_sha256=<evidence_sha256>
claimant=<claimant>
timestamp_utc=<timestamp_utc>

Rules:
- Keys are fixed and ordered exactly as above.
- Values are trimmed.
- Newlines are '\n'.
- Addresses are lowercased.
- evidence_sha256 is lowercased (or empty string if not provided).

This produces a deterministic claim_id usable across chains and layers.

---

## 3) Truth Ledger Folder Layout

truth-ledger/claims/<CLAIM_ID>/
  claim.json
  stake_receipt.txt
  bond_receipt.txt
  payout_receipt.txt

---

End of standard.
