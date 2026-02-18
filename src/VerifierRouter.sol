// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IProofVerifier.sol";

contract VerifierRouter {
    // systemId => verifier contract
    mapping(uint32 => address) public verifiers;

    event VerifierSet(uint32 indexed systemId, address indexed verifier);

    function setVerifier(uint32 systemId, address verifier) external {
        // v0: permissionless set; governance later
        verifiers[systemId] = verifier;
        emit VerifierSet(systemId, verifier);
    }

    function verify(uint32 systemId, bytes calldata proof, bytes32 publicInputsHash) external view returns (bool) {
        address v = verifiers[systemId];
        require(v != address(0), "no verifier");
        return IProofVerifier(v).verify(proof, publicInputsHash);
    }
}
