// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "lib/forge-std/src/Script.sol";
import {MultiSig} from "../src/MultiSig.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract MultiSigScript is Script {
    MultiSig public multiSig;

    function setUp() public {}
    function deploy(address addr) public returns(MultiSig) {
        
                HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory networkConfig = helperConfig.getActiveNetworkConfig();
        vm.startBroadcast(addr);

        multiSig = new MultiSig(networkConfig.priceFeed);

        vm.stopBroadcast();
        return multiSig;
        
    }

    function run() public returns (MultiSig) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory networkConfig = helperConfig.getActiveNetworkConfig();
        vm.startBroadcast();

        multiSig = new MultiSig(networkConfig.priceFeed);

        vm.stopBroadcast();
        return multiSig;
    }
}
