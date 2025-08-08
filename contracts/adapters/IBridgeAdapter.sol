// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IBridgeAdapter {
    event BridgeInitiated(address indexed token, uint256 amount, address indexed to);

    function bridge(address token, uint256 amount, address to) external;
}
