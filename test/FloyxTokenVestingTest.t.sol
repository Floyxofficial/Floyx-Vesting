// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "src/FloyxTokenVesting.sol";
import "src/Floyx.sol";

contract FloyxTokenVestingTest is Test {
    // Contracts
    FloyxTokenVesting vestingContract;
    Floyx floyx;
    // Test data
    address beneficiary;
    uint256 startTime;
    uint256 cliff;
    uint256 duration;
    uint256 slicePeriod;
    uint256 amountTotal;
    uint8 releasedPercent;
    uint256 tgeAmount;
    address owner;

    function setUp() public returns (FloyxTokenVesting) {
        owner = address(this);
        floyx = new Floyx();
        vestingContract = new FloyxTokenVesting(address(floyx));

        beneficiary = address(0x123);
        startTime = block.timestamp + 60; // 1 minute from now
        cliff = 30; // 30 days
        duration = 180; // 180 days
        slicePeriod = 30; // 30 days
        amountTotal = 1000; // 1000 tokens
        releasedPercent = 100; // 10% per slice period (in multiples of 10)
        tgeAmount = 100; // 100 tokens
        return vestingContract;
    }

    function testInputSetupt() public {
        assertEq(beneficiary, address(0x123));
        assertEq(startTime, block.timestamp + 60);
        assertEq(cliff, 30);
        assertEq(duration, 180);
        assertEq(slicePeriod, 30);
        assertEq(amountTotal, 1000);
        assertEq(releasedPercent, 100);
        assertEq(tgeAmount, 100);
    }

    function testgetAllVestedAmount() public {
        assertEq(vestingContract.getTotalVestingAmount(), 0);
    }

    function testgetAllTokenAvailable() public {
        assertEq(vestingContract.getTotalReleasedAmount(), 0);
    }

    function testGetTotalReleasedAmount() public {
        assertEq(vestingContract.getTotalReleasedAmount(), 0);
    }

    function testSeedVestingScheduleFailed() public {
        vm.expectRevert(bytes("Insufficient funds available"));
        vestingContract.SeedVestingSchedule(beneficiary, amountTotal);
    }

    function testPrivateVestingScheduleFailed() public {
        vm.expectRevert(bytes("Insufficient funds available"));
        vestingContract.SeedVestingSchedule(beneficiary, amountTotal);
    }

    function testMint() public {
        uint256 amount = 1000000 ether;
        floyx.mint(owner, amount);

        assertEq(floyx.totalSupply(), amount);
        assertEq(floyx.balanceOf(owner), amount);
    }

    function testgetAvailableFunds() public {
        assertEq(vestingContract.getAvailableFunds(), 0);
    }

    function testgetUnallocatedFundsAmount() public {
        assertEq(vestingContract.getUnallocatedFundsAmount(), 0);
    }

    function testwithdrawUnallocatedFunds() public {
        uint256 amount = 100;
        vm.expectRevert(bytes("Invalid amount of unallocated funds."));
        vestingContract.withdrawUnallocatedFunds(address(1), amount);
    }

    function testGetClaimableAmount() public {
        vm.expectRevert(bytes("Vesting schedule not initialized"));
        vestingContract.getClaimableAmount(address(123));
    }

    function testclaimVestedToken() public {
        vm.expectRevert(bytes("Vesting schedule not initialized"));
        vestingContract.claimVestedToken(address(234));
    }
}
