// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract VATAToken is ERC20, Ownable {
    constructor(address owner_) ERC20("VATA Protocol Token", "VATA") Ownable(owner_) {
        _mint(owner_, 1_000_000_000 ether);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}
