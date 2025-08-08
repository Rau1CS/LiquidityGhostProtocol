// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../adapters/IBridgeAdapter.sol";

contract MockBridgeAdapter is IBridgeAdapter {
    function bridge(address token, uint256 amount, address to) external override {
        emit BridgeInitiated(token, amount, to);
    }
}
