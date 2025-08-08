// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IBridgeAdapter {
    event Sent(address indexed token, uint256 amount, uint16 dstChainId, bytes32 guid, bytes memo);
    event Received(address indexed token, uint256 amount, uint16 srcChainId, bytes32 guid, bytes payload);

    function send(address token, uint256 amount, uint16 dstChainId, bytes calldata memo) external payable returns (bytes32 guid);
    function deliver(bytes32 guid, bytes calldata payload) external;
}
