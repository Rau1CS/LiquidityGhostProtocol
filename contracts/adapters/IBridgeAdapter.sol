// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IBridgeAdapter {
    event Sent(address indexed token, uint256 amount, address indexed to);
    event Received(address indexed token, uint256 amount, address indexed from);

    function send(address token, uint256 amount, address to, bytes calldata data) external;
    function onReceive(address token, uint256 amount, address from, bytes calldata data) external;
}

