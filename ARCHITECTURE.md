
No human trust assumptions exist beyond cryptography.

---

## 6. Failure Modes

| Failure | Result |
|-------|-------|
| Wrong inputs | Root mismatch |
| Tampered output | Root mismatch |
| Invalid proof | Verifier rejects |
| Forged receipt | Onchain check fails |
| Altered history | Blockchain consensus rejects |

All failures are detectable.

---

## 7. Scalability

- Only bytes32 roots stored onchain
- Proofs verify in constant time
- Artifacts stored offchain

VATA scales with storage and computation, not blockchain state.

---

## 8. Upgrade Strategy

- Verifier contracts can be versioned
- Anchor registry can support multiple verifier addresses
- Epoch receipts include version metadata

Old epochs remain valid forever.

---

## 9. Design Philosophy

- Minimal surface area
- Deterministic by default
- Cryptography over reputation
- Auditability over opacity

---

End of Architecture.