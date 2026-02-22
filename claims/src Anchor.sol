// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IVerifier {
    function verifyProof(
        uint256[2] calldata a,
        uint256[2][2] calldata b,
        uint256[2] calldata c,
        uint256[1] calldata input
    ) external view returns (bool);
}

contract Anchor {
    IVerifier public immutable VERIFIER;
    mapping(bytes32 => bool) public anchored;

    event Anchored(bytes32 indexed commitment, address indexed sender);

    constructor(address verifier_) {
        VERIFIER = IVerifier(verifier_);
    }

    function anchor(
        uint256[2] calldata a,
        uint256[2][2] calldata b,
        uint256[2] calldata c,
        uint256[1] calldata input
    ) external {
        require(VERIFIER.verifyProof(a, b, c, input), "BAD_PROOF");
        bytes32 commitment = bytes32(input[0]);
        anchored[commitment] = true;
        emit Anchored(commitment, msg.sender);
    }
}