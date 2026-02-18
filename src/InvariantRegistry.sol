// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract InvariantRegistry {
    struct Invariant {
        bytes32 invariantHash;
        string description;
        uint32 version;
        bool active;
    }

    mapping(bytes32 => Invariant) public invariants;

    event InvariantUpserted(bytes32 indexed id, bytes32 invariantHash, uint32 version, bool active);
    event InvariantDisabled(bytes32 indexed id);

    function upsertInvariant(
        bytes32 id,
        bytes32 invariantHash,
        string calldata description,
        uint32 version,
        bool active
    ) external {
        invariants[id] = Invariant(invariantHash, description, version, active);
        emit InvariantUpserted(id, invariantHash, version, active);
    }

    function disableInvariant(bytes32 id) external {
        invariants[id].active = false;
        emit InvariantDisabled(id);
    }
}
