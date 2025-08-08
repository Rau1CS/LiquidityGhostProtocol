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
        FeeSplitter splitter = new FeeSplitter();
        EarningsEscrow escrow = new EarningsEscrow(1 days, address(this), splitter);
        Reputation rep = new Reputation();
        core = new LGPCore(escrow, rep, splitter);
    }

    function testDefaults() public {
        assertEq(core.protocolFeeBps(), 1500);
        assertEq(core.holdbackBps(), 1000);
    }
}

