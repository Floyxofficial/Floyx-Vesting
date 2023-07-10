// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "src/Floyx.sol";

interface MintableToken {
    function mint(address, uint256) external;
}

contract FloyxTest is Test {
    Floyx floyx;
    address owner;

    function setUp() public {
        floyx = new Floyx();
        owner = address(this);
    }

    function testTokenNameAndSymbol() public {
        string memory expectedName = "Floyx";
        string memory expectedSymbol = "FLOYX";

        assertEq(floyx.name(), expectedName);
        assertEq(floyx.symbol(), expectedSymbol);
    }

    function testMaxSupply() public {
        uint256 expectedMaxSupply = 50000000000 ether;
        assertEq(floyx.MAX_SUPPLY(), expectedMaxSupply);
    }

    function testMint() public {
        uint256 amount = 1000 ether;
        floyx.mint(owner, amount);

        assertEq(floyx.totalSupply(), amount);
        assertEq(floyx.balanceOf(owner), amount);
    }

    function testMintExceedMaxSupply() public {
        uint256 initialSupply = floyx.totalSupply();
        assertEq(floyx.totalSupply(), initialSupply);
        assertEq(floyx.balanceOf(owner), 0);
    }
}
