# VATA Protocol Threat Model

This document describes the adversarial assumptions, attack surfaces, and security guarantees of the VATA (Verifiable Anchored Truth Architecture) protocol.

The purpose of this threat model is to clearly define what VATA defends against, what it does not defend against, and why its security properties hold.

---

## 1. Adversary Model

VATA assumes adversaries may:

- Control client software
- Control epoch builders
- Control proof generators
- Control offchain storage
- Attempt to forge receipts
- Attempt to alter history
- Attempt to submit invalid proofs
- Attempt to confuse verifiers

VATA does **not** assume adversaries can:

- Break standard cryptographic primitives
- Break blockchain consensus
- Forge digital signatures

---

## 2. Assets

The protocol protects:

- Integrity of epoch data
- Integrity of computation outputs
- Authenticity of receipts
- Immutability of anchored commitments

---

## 3. Security Goals

VATA guarantees:

- Tamper evidence
- Deterministic reproducibility
- Public verifiability
- Historical immutability

VATA does not guarantee:

- Confidentiality (unless layered with encryption)
- Availability of offchain storage
- Truthfulness of real-world inputs

---

## 4. Trust Assumptions

Trusted:

- Cryptographic hash functions
- Proof system soundness
- Blockchain consensus

Untrusted:

- Operators
- Hardware
- Clients
- Storage

---

## 5. Attack Surfaces

- Input manipulation
- Output manipulation
- Proof forgery
- Receipt forgery
- Replay attacks
- Anchor registry misuse
- Verifier contract bugs

---

## 6. Attack Analysis

### 6.1 Input Tampering

**Attack:** Modify inputs after epoch creation  
**Result:** Merkle root mismatch → detection

---

### 6.2 Output Tampering

**Attack:** Modify outputs  
**Result:** Merkle root mismatch → detection

---

### 6.3 Proof Forgery

**Attack:** Submit invalid proof  
**Result:** Verifier rejects

---

### 6.4 Receipt Forgery

**Attack:** Fabricate receipt  
**Result:** Onchain root check fails

---

### 6.5 Replay Attack

**Attack:** Resubmit old proof  
**Result:** Root already anchored or treated as duplicate

---

### 6.6 Anchor Registry Corruption

**Attack:** Modify registry state  
**Result:** Requires blockchain consensus failure

---

### 6.7 Malicious Operator

**Attack:** Operator lies about computation  
**Result:** Anyone can re-run verification and detect mismatch

---

## 7. Non-Goals

VATA does not attempt to solve:

- Sybil resistance
- Economic incentives
- Consensus design
- Identity

VATA focuses solely on cryptographic integrity.

---

## 8. Denial of Service

Adversaries may:

- Spam verifier
- Flood RPC endpoints

Mitigation:

- Gas costs
- Rate limiting
- Multiple RPC providers

---

## 9. Upgradability Risks

Risks:

- Buggy verifier upgrade
- Incompatible proof formats

Mitigation:

- Versioned verifier contracts
- Immutable old verifiers
- Epoch receipts include version metadata

---

## 10. Residual Risks

- Cryptographic primitive failure
- Blockchain collapse
- Catastrophic software bug

These are systemic risks inherent to all cryptographic systems.

---

## 11. Summary

VATA provides **integrity, not truth**.

It guarantees that:

> If something is claimed, it can be proven or disproven cryptographically.

It does not decide what is true — it decides whether claims are **verifiably consistent**.

---

End of Threat Model.