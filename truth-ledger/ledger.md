# VATA Truth Ledger — Genesis

VATA is a Truth Settlement Layer:  
a blockchain-native system for economically settling contested factual claims.

Each entry in this ledger represents a claim that was:

- Bonded with stake
- Optionally challenged with bond
- Economically resolved on-chain
- Verifiable via transaction receipts

Ethereum settles value.  
VATA settles truth.

---

## Ledger Entries

| Claim ID | Domain | Claim Summary | Stake | Bond | Outcome | Resolution Payout TX |
|---------|--------|--------------|-------|------|---------|---------------------|
| 0xd9c54a9c47237c84307fb83f8fc0bf4651b4ca2099de2d55a53f5f4fe75ca1c4 | ai.forensics | Model output contains poisoned reasoning | 1000 VATA | 500 VATA | Challenger wins | 0xf6eba090caec36fe30b37bdbdcd778cefa3e8a0d9ae8b6bde590a5749f5e8298 |

---

## Verification

Each claim has a folder under:

truth-ledger/claims/<CLAIM_ID>/

containing:

- claim.json  
- stake_receipt.txt  
- bond_receipt.txt  
- payout_receipt.txt  

Anyone can independently verify every entry.
