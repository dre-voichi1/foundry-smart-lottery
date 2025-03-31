// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "@forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

/// @dev Use abstract contracts for constant values in other contracts
abstract contract CodeConstants {
    /* Chainlink VRF Values */
    uint96 public constant MOCK_BASE_FEE = 0.25 ether;
    uint96 public constant MOCK_GAS_PRICE_LINK = 1e9;

    // LINK / ETH price
    int256 public constant MOCK_WEI_PER_UNIT_LINK = 4e15;

    /* Chain IDs */
    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
}

contract HelperConfig is Script, CodeConstants {
    // Errors
    error HelperConfig__InvalidChainId();

    // State variables
    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint256 subscriptionId;
        uint32 callbackGasLimit;
    }

    NetworkConfig public localNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
    }

    function getConfig() public returns (NetworkConfig memory) {
        getConfigByChainId(block.chainid);
    }

    /// @return - Returns NetworkConfig with adjusted values based on the Chain ID
    function getConfigByChainId(
        uint256 chainId
    ) public returns (NetworkConfig memory) {
        if (networkConfigs[chainId].vrfCoordinator != address(0)) {
            return networkConfigs[chainId];
        } else if (chainId == LOCAL_CHAIN_ID) {
            return getOrCreateLocalNetworkConfig();
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

    /// @dev All these other functions return a NetworkConfig with values adjusted according to the network
    function getOrCreateLocalNetworkConfig()
        public
        returns (NetworkConfig memory)
    {
        /* Checks */
        // Check for active local network config for anvil
        if (localNetworkConfig.vrfCoordinator != address(0)) {
            return localNetworkConfig;
        }

        /* Effects / Interactions */
        // Deploy mocks and such
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinator = new VRFCoordinatorV2_5Mock(
            MOCK_BASE_FEE,
            MOCK_GAS_PRICE_LINK,
            MOCK_WEI_PER_UNIT_LINK
        );
        vm.stopBroadcast();

        localNetworkConfig = NetworkConfig({
            entranceFee: 0.01 ether,
            interval: 30, // 30 seconds
            vrfCoordinator: address(vrfCoordinator),
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae, // gasLane doesn't really matter
            callbackGasLimit: 500000,
            subscriptionId: 0
        });

        return localNetworkConfig;
    }

    /* View / Pure functions (Getter functions) */
    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                entranceFee: 0.01 ether, // 1e16
                interval: 30, // 30 seconds
                vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
                // gasLane doesn't really matter (works no matter what)
                gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
                callbackGasLimit: 5000000, // 500,000 gas
                subscriptionId: 0
            });
    }
}
