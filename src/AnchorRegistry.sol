// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract AnchorRegistry {
    struct Anchor {
        uint64 chainId;
        bytes32 txHash;
        bytes32 payloadHash;
        uint40  timestamp;
    }

    mapping(bytes32 => Anchor[]) private _anchors;

    event Anchored(bytes32 indexed claimId, uint64 indexed chainId, bytes32 txHash, bytes32 payloadHash);

    function anchor(bytes32 claimId, uint64 chainId, bytes32 txHash, bytes32 payloadHash) external {
        _anchors[claimId].push(Anchor({
            chainId: chainId,
            txHash: txHash,
            payloadHash: payloadHash,
            timestamp: uint40(block.timestamp)
        }));
        emit Anchored(claimId, chainId, txHash, payloadHash);
    }

    function anchorCount(bytes32 claimId) external view returns (uint256) {
        return _anchors[claimId].length;
    }

    function anchorAt(bytes32 claimId, uint256 idx) external view returns (Anchor memory) {
        return _anchors[claimId][idx];
    }
}
