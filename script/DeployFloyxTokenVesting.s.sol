// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import {FloyxTokenVesting} from "src/FloyxTokenVesting.sol";

contract FloyxTokenVestingScript is Script {
    function run() external returns (FloyxTokenVesting) {
        vm.startBroadcast();
        FloyxTokenVesting floyxTokenVesting = new FloyxTokenVesting(
            0x41081E433e62caE7a19C966dd5b5838693D52058
        );
        vm.stopBroadcast();
        return floyxTokenVesting;
    }
}
