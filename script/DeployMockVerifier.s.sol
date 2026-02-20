pragma solidity ^0.8.20;
import "forge-std/Script.sol";
import {MockVerifier} from "../test/MockVerifier.sol";

contract DeployMockVerifier is Script {
    function run() external returns (address) {
        vm.startBroadcast(vm.envUint("PK"));
        MockVerifier v = new MockVerifier();
        vm.stopBroadcast();
        return address(v);
    }
}
