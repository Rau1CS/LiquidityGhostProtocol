// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {LGPCore} from "contracts/core/LGPCore.sol";
import {EarningsEscrow} from "contracts/core/EarningsEscrow.sol";
import {Reputation} from "contracts/core/Reputation.sol";
import {FeeSplitter} from "contracts/core/FeeSplitter.sol";

contract LGPCore_CompileTest is Test {
    LGPCore core;

    function setUp() public {
        EarningsEscrow escrow = new EarningsEscrow();
        Reputation rep = new Reputation();
        FeeSplitter splitter = new FeeSplitter();
        core = new LGPCore(escrow, rep, splitter);
    }

    function testDefaults() public {
        assertEq(core.protocolFeeBps(), 1500);
        assertEq(core.holdbackBps(), 1000);
    }
}

