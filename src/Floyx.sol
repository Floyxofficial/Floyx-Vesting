// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Floyx is ERC20, Ownable {
    uint256 public constant MAX_SUPPLY = 50000000000 ether;

    constructor() ERC20("Floyx", "FLOYX") {}

    function mint(address to, uint256 amount) external onlyOwner {
        require(MAX_SUPPLY >= amount + totalSupply(), "Floyx: Can not exceed max supply");
        _mint(to, amount);
    }
}
