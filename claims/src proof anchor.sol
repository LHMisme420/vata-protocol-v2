// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface IVerifier {
    function verifyProof(
        uint256[2] calldata a,
        uint256[2][2] calldata b,
        uint256[2] calldata c,
        uint256[] calldata input
    ) external view returns (bool);
}

contract ProofAnchor {
    IVerifier public immutable verifier;

    event ProofVerified(bytes32 indexed proofId, address indexed sender);

    constructor(address _verifier) {
        verifier = IVerifier(_verifier);
    }

    function verifyAndEmit(
        uint256[2] calldata a,
        uint256[2][2] calldata b,
        uint256[2] calldata c,
        uint256[] calldata input
    ) external returns (bytes32 proofId) {
        require(verifier.verifyProof(a, b, c, input), "BAD_PROOF");
        proofId = keccak256(abi.encode(a, b, c, input));
        emit ProofVerified(proofId, msg.sender);
    }
}