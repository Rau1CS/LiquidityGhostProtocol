// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./EarningsEscrow.sol";
import "./Reputation.sol";
import "./FeeSplitter.sol";

contract LGPCore {
    uint256 public constant PROTOCOL_FEE_BPS = 1500;
    uint256 public constant HOLD_BACK_BPS = 1000;
    uint256 public constant HOLD_BACK_TTL = 24 hours;
    uint256 public constant MIN_PROFIT_USD = 80;
    uint256 public constant BRIDGE_TIMEOUT = 8 minutes;
    uint256 public constant MAX_SLIPPAGE_BPS = 50;

    EarningsEscrow public immutable escrow;
    Reputation public immutable reputation;
    FeeSplitter public immutable feeSplitter;

    event RescueExecuted(address indexed rescuer, address indexed user, uint256 profit, uint256 fee, uint256 holdback);

    constructor(EarningsEscrow _escrow, Reputation _reputation, FeeSplitter _feeSplitter) {
        escrow = _escrow;
        reputation = _reputation;
        feeSplitter = _feeSplitter;
    }

    function rescue(address user, uint256 profit) external {
        require(profit >= MIN_PROFIT_USD, "profit too low");

        uint256 fee = (profit * PROTOCOL_FEE_BPS) / 10000;
        uint256 holdback = (profit * HOLD_BACK_BPS) / 10000;

        feeSplitter.split(fee, msg.sender);
        escrow.deposit(user, holdback, HOLD_BACK_TTL);

        reputation.increment(msg.sender);

        emit RescueExecuted(msg.sender, user, profit, fee, holdback);
    }
}
