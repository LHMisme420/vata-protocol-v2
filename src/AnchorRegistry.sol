// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice AnchorRegistry for VATA (single-constructor, backward compatible)
/// - old tests: new AnchorRegistry() works
/// - old API: anchor(...) + anchorCount(...)
/// - new API: anchorRoot(epoch, root, payloadHash, uri) + isRoot(...)
contract AnchorRegistry {
    error NotOwner();
    error RootAlreadyAnchored();
    error ZeroRoot();
    error ZeroEpoch();

    // Canonical registry event
    event RootAnchored(
        uint64 indexed epoch,
        bytes32 indexed root,
        bytes32 payloadHash,
        string uri,
        address indexed sender
    );

    // Legacy anchoring event (for ClaimRegistry tests)
    event Anchored(
        bytes32 indexed claimId,
        uint256 indexed epoch,
        bytes32 artifactRoot,
        bytes32 payloadHash,
        address indexed sender
    );

    address public owner;

    // Canonical epoch registry
    mapping(uint64 => bytes32) public rootByEpoch; // epoch -> root
    mapping(bytes32 => uint64) public epochByRoot; // root -> epoch (0 = absent)

    // Legacy: claimId -> anchor count
    mapping(bytes32 => uint256) private _anchorCount;

    /// @notice Single constructor to satisfy Solidity + existing tests.
    ///         Owner defaults to deployer.
    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    // ===== Canonical onchain root registry =====

    function anchorRoot(
        uint64 epoch,
        bytes32 root,
        bytes32 payloadHash,
        string calldata uri
    ) external onlyOwner {
        if (epoch == 0) revert ZeroEpoch();
        if (root == bytes32(0)) revert ZeroRoot();
        if (rootByEpoch[epoch] != bytes32(0)) revert RootAlreadyAnchored();
        if (epochByRoot[root] != 0) revert RootAlreadyAnchored();

        rootByEpoch[epoch] = root;
        epochByRoot[root] = epoch;

        emit RootAnchored(epoch, root, payloadHash, uri, msg.sender);
    }

    function isRoot(bytes32 root) external view returns (bool) {
        return epochByRoot[root] != 0;
    }

    // ===== Legacy compatibility =====

    function anchorCount(bytes32 claimId) external view returns (uint256) {
        return _anchorCount[claimId];
    }

    /// @notice Legacy method expected by your tests:
    /// a.anchor(claimId, 1, artifactRoot, payloadHash)
    function anchor(
        bytes32 claimId,
        uint256 epoch,
        bytes32 artifactRoot,
        bytes32 payloadHash
    ) external {
        _anchorCount[claimId] += 1;
        emit Anchored(claimId, epoch, artifactRoot, payloadHash, msg.sender);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
    }
}