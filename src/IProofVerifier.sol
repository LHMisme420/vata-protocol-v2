// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IProofVerifier {
    // Returns true if proof verifies for the given public inputs
    function verify(bytes calldata proof, bytes32 publicInputsHash) external view returns (bool);
}
