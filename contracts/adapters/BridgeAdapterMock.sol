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

    // naive GUID generator
    function _guid(address token, uint256 amount, uint16 dstChainId, address sender, uint256 nonce)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(token, amount, dstChainId, sender, nonce));
    }

    uint256 public nonce;

    function send(address token, uint256 amount, uint16 dstChainId, bytes calldata memo)
        external
        payable
        override
        returns (bytes32 guid)
    {
        guid = _guid(token, amount, dstChainId, msg.sender, ++nonce);
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

    /// In real bridges this would be called by the dst endpoint.
    /// Our tests/sim call it when latency is "over".
    function deliver(bytes32 guid, bytes calldata payload) external override {
        Packet storage p = packets[guid];
        require(!p.delivered, "ALREADY_DELIVERED");
        p.delivered = true;
        // For simplicity, deliver funds to the original sender on dst chain emulated by test harness
        // The test will simulate that adapter exists on both chains; this contract only logs the event.
        emit Received(p.token, p.amount, /*srcChainId*/ 0, guid, payload);
    }
}
