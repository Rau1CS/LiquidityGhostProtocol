// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {IBridgeAdapter} from "./IBridgeAdapter.sol";

contract BridgeAdapterMock is IBridgeAdapter {
    struct Packet {
        address token;
        uint256 amount;
        uint16 dstChainId;
        address sender;
        bool delivered;
        bytes memo;
    }

    mapping(bytes32 => Packet) public packets;

    // rename to avoid param shadowing
    uint256 public nonceCounter;

    function _guid(
        address token,
        uint256 amount,
        uint16 dstChainId,
        address sender,
        uint256 nonce_
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(token, amount, dstChainId, sender, nonce_));
    }

    function send(
        address token,
        uint256 amount,
        uint16 dstChainId,
        bytes calldata memo
    ) external payable override returns (bytes32 guid) {
        guid = _guid(token, amount, dstChainId, msg.sender, ++nonceCounter);
        packets[guid] = Packet({
            token: token,
            amount: amount,
            dstChainId: dstChainId,
            sender: msg.sender,
            delivered: false,
            memo: memo
        });
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        emit Sent(token, amount, dstChainId, guid, memo);
    }

    function deliver(bytes32 guid, bytes calldata payload) external override {
        Packet storage p = packets[guid];
        require(!p.delivered, "ALREADY_DELIVERED");
        p.delivered = true;
        emit Received(p.token, p.amount, /*srcChainId*/ 0, guid, payload);
    }
}
