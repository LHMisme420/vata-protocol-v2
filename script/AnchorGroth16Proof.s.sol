pragma solidity ^0.8.24;
import "forge-std/Script.sol";

interface IRegistry {
  function verifyAndAnchorGroth16(
    uint256[2] calldata A,
    uint256[2][2] calldata B,
    uint256[2] calldata C,
    uint256[] calldata inputs
  ) external;
}

contract AnchorGroth16Proof is Script {
  function run() external {
    address registry = vm.envAddress("REGISTRY");
    string memory json = vm.readFile("proof_full.json");

    uint256[] memory a3 = abi.decode(vm.parseJson(json, ".proof.pi_a"), (uint256[]));
    uint256[][] memory b3 = abi.decode(vm.parseJson(json, ".proof.pi_b"), (uint256[][]));
    uint256[] memory c3 = abi.decode(vm.parseJson(json, ".proof.pi_c"), (uint256[]));
    uint256[] memory inputs = abi.decode(vm.parseJson(json, ".publicSignals"), (uint256[]));

    uint256[2] memory A = [a3[0], a3[1]];

    // bn128 Groth16 wants B as [ [b00,b01], [b10,b11] ] where each inner pair is (x,y)
    // snarkjs exports pi_b as [ [x1,y1], [x2,y2], [1,0] ] -> we take first two rows only
    uint256[2] memory b0 = [b3[0][0], b3[0][1]];
    uint256[2] memory b1 = [b3[1][0], b3[1][1]];
    uint256[2][2] memory B = [[b0[1], b0[0]], [b1[1], b1[0]]];

    uint256[2] memory C = [c3[0], c3[1]];

    vm.startBroadcast();
    IRegistry(registry).verifyAndAnchorGroth16(A,B,C,inputs);
    vm.stopBroadcast();
  }
}
