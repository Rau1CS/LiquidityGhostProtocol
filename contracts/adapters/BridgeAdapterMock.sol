// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IBridgeAdapter} from "./IBridgeAdapter.sol";

contract BridgeAdapterMock is IBridgeAdapter {
    function send(address token, uint256 amount, address to, bytes calldata data) external override {
        emit Sent(token, amount, to);
    }

    function onReceive(address token, uint256 amount, address from, bytes calldata data) external override {
        emit Received(token, amount, from);
    }
}

