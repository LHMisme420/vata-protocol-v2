// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/VATAToken.sol";
import "../src/AnchorRegistry.sol";
import "../src/VerifierRouter.sol";
import "../src/ClaimRegistry.sol";
import "./MockVerifier.sol";

contract ClaimRegistryTest is Test {
    VATAToken token;
    AnchorRegistry a;
    VerifierRouter r;
    ClaimRegistry reg;
    MockVerifier mv;

    address alice = address(0xA11CE);
    address bob   = address(0xB0B);

    function setUp() public {
        token = new VATAToken(address(this));
        a = new AnchorRegistry();
        r = new VerifierRouter();
        mv = new MockVerifier();

        // systemId 1 => mock verifier
        r.setVerifier(1, address(mv));

        reg = new ClaimRegistry(address(token), address(a), address(r));

        token.mint(alice, 10_000 ether);
        token.mint(bob,   10_000 ether);

        vm.prank(alice);
        token.approve(address(reg), type(uint256).max);

        vm.prank(bob);
        token.approve(address(reg), type(uint256).max);

        // make finalization easy here: require 1 anchor
        reg.setParams(1 days, 1000 ether, 500 ether, 1);
    }

    function test_submit_and_finalize() public {
        bytes32 claimId = keccak256("claim1");
        vm.prank(alice);
        reg.submitClaim(claimId, keccak256("artifact"), keccak256("proofs"), 1000 ether);

        // add 1 anchor
        a.anchor(claimId, 1, bytes32(uint256(0x1111)), keccak256("payload"));

        vm.warp(block.timestamp + 2 days);

        uint256 beforeBal = token.balanceOf(alice);
        reg.finalizeClaim(claimId);
        uint256 afterBal = token.balanceOf(alice);

        assertEq(afterBal, beforeBal + 1000 ether);
    }

    function test_challenge_slash_requires_valid_proof() public {
        bytes32 claimId = keccak256("claim2");
        vm.prank(alice);
        reg.submitClaim(claimId, keccak256("artifact2"), keccak256("proofs2"), 1000 ether);

        vm.prank(bob);
        reg.challengeClaim(claimId, 500 ether);

        // invalid proof should revert
        vm.prank(bob);
        vm.expectRevert(bytes("fraud proof invalid"));
        reg.slashClaim(claimId, 1, hex"00");

        // valid proof (0x01) should slash
        uint256 before = token.balanceOf(bob);
        vm.prank(bob);
        reg.slashClaim(claimId, 1, hex"01");
        uint256 after_ = token.balanceOf(bob);

        assertEq(after_, before + 1500 ether);
    }
}
