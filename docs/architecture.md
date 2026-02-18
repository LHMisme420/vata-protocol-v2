# VATA Protocol v2 — Defiance Oracle Network (DON)

## Overview
DON is a permissionless, multi-prover, cross-chain verification protocol for AI forensics.

## Core Objects
- Artifact Pack (canonicalized)
- artifact_root (Merkle root)
- Proof Bundle (multi-system)
- proof_bundle_root (Merkle root)
- Cross-chain Anchor Set (>=N chains)

## Lifecycle
PENDING → PROVEN → ANCHORED → FINAL
or PENDING → CHALLENGED → FRAUD

## Roles
- Submitter (stakes, submits artifacts)
- Prover (generates zk proofs)
- Validator/Challenger (re-verifies & disputes)
- Indexer (aggregates state)

## Cryptographic Commitments
anchor_payload = keccak256(claim_id | artifact_root | proof_bundle_root | timestamp | stake)

## Next Specs to Implement
1. Invariant DSL + version registry
2. ClaimRegistry contract (staking/challenge)
3. Proof bundle ABI format
4. Multi-chain anchoring relayer + indexer
