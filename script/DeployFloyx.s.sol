// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import {Floyx} from "src/Floyx.sol";

contract FloyxScript is Script {
    function run() external returns (FLOYXTOKEN) {
        vm.startBroadcast();
        FLOYXTOKEN floyx = new FLOYXTOKEN();
        vm.stopBroadcast();
        return floyx;
    }
}
