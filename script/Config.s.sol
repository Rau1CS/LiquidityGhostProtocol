// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {LGPCore} from "contracts/core/LGPCore.sol";

contract ConfigScript is Script {
    function run() external {
        LGPCore core = LGPCore(vm.envAddress("CORE"));
        address exoticPool = vm.envAddress("EXOTIC_POOL");

        vm.startBroadcast();
        core.setChainAllowed(8453, true);
        core.setChainAllowed(1, false);
        core.setMarketAllowed(exoticPool, true);
        core.setHoldbackTTL(24 hours);
        vm.stopBroadcast();
    }
}

