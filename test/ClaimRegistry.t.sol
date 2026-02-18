// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/VATAToken.sol";
import "../src/ClaimRegistry.sol";

contract ClaimRegistryTest is Test {
    VATAToken token;
    ClaimRegistry reg;

    address alice = address(0xA11CE);
    address bob   = address(0xB0B);

    function setUp() public {
        token = new VATAToken(address(this));
        reg = new ClaimRegistry(address(token));

        token.mint(alice, 10_000 ether);
        token.mint(bob,   10_000 ether);

        vm.prank(alice);
        token.approve(address(reg), type(uint256).max);

        vm.prank(bob);
        token.approve(address(reg), type(uint256).max);
    }

    function test_submit_and_finalize() public {
        bytes32 claimId = keccak256("claim1");
        bytes32 aRoot = keccak256("artifact");
        bytes32 pRoot = keccak256("proofs");

        vm.prank(alice);
        reg.submitClaim(claimId, aRoot, pRoot, 1000 ether);

        vm.warp(block.timestamp + 2 days);

        uint256 beforeBal = token.balanceOf(alice);
        reg.finalizeClaim(claimId);
        uint256 afterBal = token.balanceOf(alice);

        assertEq(afterBal, beforeBal + 1000 ether);
    }

    function test_challenge_and_slash() public {
        bytes32 claimId = keccak256("claim2");
        bytes32 aRoot = keccak256("artifact2");
        bytes32 pRoot = keccak256("proofs2");

        vm.prank(alice);
        reg.submitClaim(claimId, aRoot, pRoot, 1000 ether);

        vm.prank(bob);
        reg.challengeClaim(claimId, 500 ether);

        uint256 before = token.balanceOf(bob);
        reg.slashClaim(claimId);
        uint256 after_ = token.balanceOf(bob);

        assertEq(after_, before + 1500 ether);
    }
}
