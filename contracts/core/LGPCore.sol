// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {EarningsEscrow} from "./EarningsEscrow.sol";
import {Reputation} from "./Reputation.sol";
import {FeeSplitter} from "./FeeSplitter.sol";

contract LGPCore {
    EarningsEscrow public immutable escrow;
    Reputation public immutable reputation;
    FeeSplitter public immutable feeSplitter;

    uint16 private constant _PROTOCOL_FEE_BPS = 1500;
    uint16 private constant _HOLD_BACK_BPS = 1000;

    event Settled(address indexed user, address indexed rescuer, uint256 profit);

    constructor(EarningsEscrow _escrow, Reputation _reputation, FeeSplitter _feeSplitter) {
        escrow = _escrow;
        reputation = _reputation;
        feeSplitter = _feeSplitter;
    }

    function protocolFeeBps() external pure returns (uint16) {
        return _PROTOCOL_FEE_BPS;
    }

    function holdbackBps() external pure returns (uint16) {
        return _HOLD_BACK_BPS;
    }

    function settle(address user, uint256 profit) external {
        emit Settled(user, msg.sender, profit);
    }
}

