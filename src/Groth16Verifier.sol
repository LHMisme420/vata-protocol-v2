pragma solidity ^0.8.20;

/// @notice TEMPORARY STUB verifier to unblock builds.
/// Replace with real snarkjs-generated Groth16 verifier once you have a .zkey.
contract Groth16Verifier {
    function verifyProof(
        uint256[2] memory,
        uint256[2][2] memory,
        uint256[2] memory,
        uint256[] memory
    ) public pure returns (bool) {
        return true;
    }

    function verify(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[] memory input
    ) public pure returns (bool) {
        a; b; c; input;
        return true;
    }

    function verifyProofBytes(bytes calldata, uint256[] calldata) external pure returns (bool) {
        return true;
    }
}