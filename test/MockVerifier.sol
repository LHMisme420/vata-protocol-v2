// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../src/IProofVerifier.sol";

contract MockVerifier is IProofVerifier {
    function verify(bytes calldata proof, bytes32) external pure returns (bool) {
        return (proof.length == 1 && proof[0] == 0x01);
    }
}
