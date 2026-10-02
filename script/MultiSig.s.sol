// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "lib/forge-std/src/Script.sol";
import {MultiSig} from "../src/MultiSig.sol";

contract MultiSigScript is Script {
    MultiSig public multiSig;

    function setUp() public {}

    function run() public returns (MultiSig) {
        vm.startBroadcast();

        multiSig = new MultiSig();

        vm.stopBroadcast();
        return multiSig;
    }
}
