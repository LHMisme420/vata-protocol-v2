// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/VATAToken.sol";
import "../src/AnchorRegistry.sol";
import "../src/VerifierRouter.sol";
import "../src/ClaimRegistry.sol";

contract ClaimRegistryAnchorsTest is Test {
    VATAToken token;
    AnchorRegistry a;
    VerifierRouter r;
    ClaimRegistry reg;

    address alice = address(0xA11CE);

    function setUp() public {
        token = new VATAToken(address(this));
        a = new AnchorRegistry();
        r = new VerifierRouter();
        reg = new ClaimRegistry(address(token), address(a), address(r));

        token.mint(alice, 10_000 ether);

        vm.prank(alice);
        token.approve(address(reg), type(uint256).max);

        // keep default minAnchors = 3
    }

    function test_finalize_requires_anchors() public {
        bytes32 claimId = keccak256("claimA");
        vm.prank(alice);
        reg.submitClaim(claimId, keccak256("artifactA"), keccak256("proofA"), 1000 ether);

        vm.warp(block.timestamp + 2 days);

        vm.expectRevert(bytes("insufficient anchors"));
        reg.finalizeClaim(claimId);

        a.anchor(claimId, 1, bytes32(uint256(0x1111)), keccak256("payload"));
        a.anchor(claimId, 8453, bytes32(uint256(0x2222)), keccak256("payload"));
        a.anchor(claimId, 42161, bytes32(uint256(0x3333)), keccak256("payload"));

        uint256 beforeBal = token.balanceOf(alice);
        reg.finalizeClaim(claimId);
        uint256 afterBal = token.balanceOf(alice);

        assertEq(afterBal, beforeBal + 1000 ether);
    }
}
