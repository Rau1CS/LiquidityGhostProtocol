// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {LGPCore} from "../contracts/core/LGPCore.sol";
import {EarningsEscrow} from "../contracts/core/EarningsEscrow.sol";
import {Reputation} from "../contracts/core/Reputation.sol";
import {FeeSplitter} from "../contracts/core/FeeSplitter.sol";

import {AaveFlashloanAdapter} from "../contracts/adapters/aave/AaveFlashloanAdapter.sol";
import {IPoolAddressesProvider} from "../contracts/adapters/aave/IAaveV3.sol";
import {IBridgeAdapter} from "../contracts/adapters/IBridgeAdapter.sol";
import {BridgeAdapterMock} from "../contracts/adapters/BridgeAdapterMock.sol";

import {IERC20} from "forge-std/interfaces/IERC20.sol";

// Mocks
import {MockERC20} from "../contracts/mocks/MockERC20.sol";
import {MockAavePool} from "../contracts/mocks/MockAavePool.sol";
import {MockAddressesProvider} from "../contracts/mocks/MockAddressesProvider.sol";
import {MockFlashCallback} from "../contracts/mocks/MockFlashCallback.sol";
import {MockLendingMarket} from "../contracts/mocks/MockLendingMarket.sol";

contract Deploy_L1 is Script {
    // Adjust if your chain IDs differ
    uint256 constant CHAINID_SEPOLIA = 11155111;

    function run() external {
        vm.startBroadcast(); // uses --private-key from CLI

        // --- Treasury (for now, deployer) ---
        address treasury = tx.origin;

        // --- Tokens & Mocks ---
        MockERC20 weth = new MockERC20("Wrapped Ether", "WETH", 18);
        // Seed some balance to the deployer/treasury if needed for tests
        weth.mint(treasury, 1_000 ether);

        // Mock lending market (target of liquidation on L1)
        MockLendingMarket market = new MockLendingMarket(address(weth));

        // --- Core contracts ---
        Reputation rep = new Reputation();
        EarningsEscrow escrow = new EarningsEscrow();
        FeeSplitter feeSplitter = new FeeSplitter();

        // LGPCore: if your constructor differs, Codex will adjust; otherwise set via inits
        LGPCore core = new LGPCore(
            address(escrow),
            address(rep),
            address(feeSplitter),
            treasury
        );

        // Optional param knobs (if present in your LGPCore)
        try core.setMarketAllowed(address(market), true) {} catch {}
        try core.setChainAllowed(CHAINID_SEPOLIA, true) {} catch {}
        try core.setTreasury(treasury) {} catch {}
        try core.setHoldbackBps(1000) {} catch {}
        try core.setFeeBps(1500) {} catch {}

        // --- Aave-like flashloan infra on L1 (mocked) ---
        MockAavePool poolL1 = new MockAavePool(IERC20(address(weth)));
        MockAddressesProvider providerL1 = new MockAddressesProvider(address(poolL1));

        // Callback used by adapter to perform the actual logic during flashloan (mock for now)
        MockFlashCallback callbackL1 = new MockFlashCallback(IERC20(address(weth)), true);

        AaveFlashloanAdapter flAdapterL1 = new AaveFlashloanAdapter(
            IPoolAddressesProvider(address(providerL1)),
            address(callbackL1)
        );

        // --- Bridge adapter (mock) ---
        BridgeAdapterMock bridgeL1 = new BridgeAdapterMock();

        vm.stopBroadcast();

        // --- Write deploy-l1.json for record-addresses.ts ---
        string memory root = string.concat(vm.projectRoot(), "/scripts/");
        string memory path = string.concat(root, "deploy-l1.json");
        string memory obj;
        obj = vm.serializeUint("lgp", "chainId", CHAINID_SEPOLIA);
        obj = vm.serializeAddress("lgp", "LGPCore", address(core));
        obj = vm.serializeAddress("lgp", "EarningsEscrow", address(escrow));
        obj = vm.serializeAddress("lgp", "Reputation", address(rep));
        obj = vm.serializeAddress("lgp", "FeeSplitter", address(feeSplitter));
        obj = vm.serializeAddress("lgp", "AaveFlashloanAdapter", address(flAdapterL1));
        obj = vm.serializeAddress("lgp", "BridgeAdapter", address(bridgeL1));
        obj = vm.serializeAddress("lgp", "MockLendingMarket", address(market));
        obj = vm.serializeAddress("lgp", "WETH", address(weth));
        obj = vm.serializeAddress("lgp", "Treasury", treasury);
        vm.writeJson(obj, path);
        console2.log("Wrote", path);
    }
}
