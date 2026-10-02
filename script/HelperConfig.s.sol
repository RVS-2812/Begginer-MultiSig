
pragma solidity ^0.8.19;
import {Script} from "lib/forge-std/src/Script.sol";
import {MockV3Aggregator} from "@chainlink/contracts/src/v0.8/shared/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script {
    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8;

    struct NetworkConfig {
        address priceFeed;
    }
    NetworkConfig public activeNetworkConfig;

    mapping(uint256 => NetworkConfig) public networkConfigs;
    constructor() {
        networkConfigs[11155111] = getSepoliaEthConfig();
        activeNetworkConfig =  getNetworkConfig(block.chainid);
    }

    function getNetworkConfig(uint256 chainId) public returns (NetworkConfig memory) {
        if(networkConfigs[chainId].priceFeed == address(0)) {
            return getOrCreateAnvilEthConfig();
        }
        return networkConfigs[chainId];
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306});
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        // If we already deployed the mock, don't deploy it again
        if (activeNetworkConfig.priceFeed != address(0)) {
            return activeNetworkConfig;
        }

        // 1. Deploy the mock
        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(
            DECIMALS,
            INITIAL_PRICE
        );
        vm.stopBroadcast();

        // 2. Return the mock's address
        return NetworkConfig({priceFeed: address(mockPriceFeed)});
    }

    function getActiveNetworkConfig() public view returns (NetworkConfig memory) {
        return activeNetworkConfig;
    }

}
