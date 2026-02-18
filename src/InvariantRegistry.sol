// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract InvariantRegistry {
    struct Invariant {
        bytes32 invariantHash;
        string description;
        uint32 version;
        bool active;
    }

    // NOTE: name is NOT "invariants" to avoid Foundry invariant-test auto-detection
    mapping(bytes32 => Invariant) public inv;

    event InvariantUpserted(bytes32 indexed id, bytes32 invariantHash, uint32 version, bool active);
    event InvariantDisabled(bytes32 indexed id);

    function upsertInvariant(
        bytes32 id,
        bytes32 invariantHash,
        string calldata description,
        uint32 version,
        bool active
    ) external {
        inv[id] = Invariant(invariantHash, description, version, active);
        emit InvariantUpserted(id, invariantHash, version, active);
    }

    function disableInvariant(bytes32 id) external {
        inv[id].active = false;
        emit InvariantDisabled(id);
    }
}
