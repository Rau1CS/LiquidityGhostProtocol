// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";

import {AaveFlashloanAdapter} from "../contracts/adapters/aave/AaveFlashloanAdapter.sol";
import {IPoolAddressesProvider} from "../contracts/adapters/aave/IAaveV3.sol";
import {BridgeAdapterMock} from "../contracts/adapters/BridgeAdapterMock.sol";

import {IERC20} from "forge-std/interfaces/IERC20.sol";

// Mocks
import {MockERC20} from "../contracts/mocks/MockERC20.sol";
import {MockAavePool} from "../contracts/mocks/MockAavePool.sol";
import {MockAddressesProvider} from "../contracts/mocks/MockAddressesProvider.sol";
import {MockFlashCallback} from "../contracts/mocks/MockFlashCallback.sol";

contract Deploy_L2 is Script {
    // Base Sepolia chainId (double-check your config; common value: 84532)
    uint256 constant CHAINID_BASE_SEPOLIA = 84532;

    function run() external {
        vm.startBroadcast();

        address treasury = tx.origin;

        // Token + mock pool on L2
        MockERC20 weth = new MockERC20("Wrapped Ether", "WETH", 18);
        weth.mint(treasury, 1_000 ether);

        MockAavePool poolL2 = new MockAavePool(IERC20(address(weth)));
        MockAddressesProvider providerL2 = new MockAddressesProvider(address(poolL2));
        MockFlashCallback callbackL2 = new MockFlashCallback(IERC20(address(weth)), true);

        AaveFlashloanAdapter flAdapterL2 = new AaveFlashloanAdapter(
            IPoolAddressesProvider(address(providerL2)),
            address(callbackL2)
        );

        BridgeAdapterMock bridgeL2 = new BridgeAdapterMock();

        vm.stopBroadcast();

        // Write deploy-l2.json
        string memory root = string.concat(vm.projectRoot(), "/scripts/");
        string memory path = string.concat(root, "deploy-l2.json");
        string memory obj;
        obj = vm.serializeUint("lgp", "chainId", CHAINID_BASE_SEPOLIA);
        obj = vm.serializeAddress("lgp", "AaveFlashloanAdapter", address(flAdapterL2));
        obj = vm.serializeAddress("lgp", "BridgeAdapter", address(bridgeL2));
        obj = vm.serializeAddress("lgp", "WETH", address(weth));
        vm.writeJson(obj, path);
        console2.log("Wrote", path);
    }
}
