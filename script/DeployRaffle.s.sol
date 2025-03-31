// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {SmartRaffle} from "src/Raffle.sol";
import {Script} from "@forge-std/Script.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract DeployRaffle is Script {
    function run() external {}

    /*
        Local -> deploy mocks, get local config
        Testnets/Mainnets -> use testnet/mainnet config
    */
    function deployContract() public returns (SmartRaffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();

        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        vm.startBroadcast();
        SmartRaffle smartRaffle = new SmartRaffle(
            config.entranceFee,
            config.interval,
            config.vrfCoordinator,
            config.gasLane,
            config.subscriptionId,
            config.callbackGasLimit
        );
        vm.stopBroadcast();

        return (smartRaffle, helperConfig);
    }
}
