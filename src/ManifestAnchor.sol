// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ManifestAnchor {
    event Anchored(bytes32 indexed manifestHash, address indexed sender);

    mapping(bytes32 => uint256) public firstSeenBlock;

    function anchor(bytes32 manifestHash) external {
        if (firstSeenBlock[manifestHash] == 0) {
            firstSeenBlock[manifestHash] = block.number;
        }
        emit Anchored(manifestHash, msg.sender);
    }

    function isAnchored(bytes32 manifestHash) external view returns (bool) {
        return firstSeenBlock[manifestHash] != 0;
    }
}