// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/VATAToken.sol";
import "../src/AnchorRegistry.sol";
import "../src/VerifierRouter.sol";
import "../src/ClaimRegistry.sol";

contract DeployDON is Script {
    function run() external returns (address token, address anchors, address router, address registry) {
        uint256 pk = vm.envUint("PK");
        address deployer = vm.addr(pk);

        vm.startBroadcast(pk);

        VATAToken t = new VATAToken(deployer);
        AnchorRegistry a = new AnchorRegistry();
        VerifierRouter r = new VerifierRouter();
        ClaimRegistry c = new ClaimRegistry(address(t), address(a), address(r));

        vm.stopBroadcast();

        token = address(t);
        anchors = address(a);
        router = address(r);
        registry = address(c);
    }
}
