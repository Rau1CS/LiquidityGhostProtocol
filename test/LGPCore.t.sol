// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../contracts/LGPCore.sol";
import "../contracts/EarningsEscrow.sol";
import "../contracts/Reputation.sol";
import "../contracts/FeeSplitter.sol";

contract LGPCoreTest {
    LGPCore core;

    function setUp() public {
        EarningsEscrow escrow = new EarningsEscrow();
        Reputation reputation = new Reputation();
        FeeSplitter feeSplitter = new FeeSplitter(address(this));
        core = new LGPCore(escrow, reputation, feeSplitter);
    }

    function testConstants() public {
        require(core.PROTOCOL_FEE_BPS() == 1500, "PROTOCOL_FEE_BPS mismatch");
        require(core.HOLD_BACK_BPS() == 1000, "HOLD_BACK_BPS mismatch");
        require(core.HOLD_BACK_TTL() == 24 hours, "HOLD_BACK_TTL mismatch");
        require(core.MIN_PROFIT_USD() == 80, "MIN_PROFIT_USD mismatch");
        require(core.BRIDGE_TIMEOUT() == 8 minutes, "BRIDGE_TIMEOUT mismatch");
        require(core.MAX_SLIPPAGE_BPS() == 50, "MAX_SLIPPAGE_BPS mismatch");
    }
}
