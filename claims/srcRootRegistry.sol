// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Minimal root registry: anchorRoot(uint256) + isRoot(uint256)
contract RootRegistry {
    // mapping root => exists
    mapping(uint256 => bool) private _root;

    // Matches your existing event topic usage (name can differ; topic depends on signature)
    event RootAnchored(uint256 root, address indexed sender);

    function anchorRoot(uint256 root) external {
        _root[root] = true;
        emit RootAnchored(root, msg.sender);
    }

    function isRoot(uint256 root) external view returns (bool) {
        return _root[root];
    }
}