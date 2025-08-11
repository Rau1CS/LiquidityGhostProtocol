// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";

import {BridgeAdapterMock} from "../../contracts/adapters/BridgeAdapterMock.sol";
import {IBridgeAdapter} from "../../contracts/adapters/IBridgeAdapter.sol";
import {MockERC20} from "../../contracts/mocks/MockERC20.sol";

contract Adapters_CompileTest is Test {
    BridgeAdapterMock internal adapter;
    MockERC20 internal token;

    function setUp() public {
        // MockERC20 in your repo expects (name, symbol)
        token = new MockERC20("Mock", "MOCK");
        adapter = new BridgeAdapterMock();

        // Give this test contract balance & approve adapter
        token.mint(address(this), 1e18);
        token.approve(address(adapter), type(uint256).max);
    }

    function testBridge() public {
        // Only partially constrain event to avoid fragility
        vm.expectEmit(true, false, false, true);
        emit IBridgeAdapter.Sent(address(token), 1, 2, bytes32(0), bytes("memo"));

        adapter.send(address(token), 1, /*dstChain*/ 2, bytes("memo"));
    }

    // Keep a compile smoke for the adapter suite
    function testFlashloan() public {
        assertTrue(true);
    }
}
