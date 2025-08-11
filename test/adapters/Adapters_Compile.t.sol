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
        token = new MockERC20("Mock", "MOCK", 18);
        adapter = new BridgeAdapterMock();

        // Mint to this test contract and approve the adapter so transferFrom succeeds
        token.mint(address(this), 1e18);
        token.approve(address(adapter), type(uint256).max);
    }

    function testBridge() public {
        // Expect the Sent event (we’ll not over-constrain indexes to avoid abi/ordering brittleness)
        vm.expectEmit(true, false, false, true);
        emit IBridgeAdapter.Sent(address(token), 1, 2, bytes32(0), bytes("memo"));

        // Call send (the adapter generates a GUID; event check only validates fields we flagged)
        adapter.send(address(token), 1, /*dstChain*/ 2, bytes("memo"));
    }

    // Keep a trivial flashloan “compile” sanity if you had it here previously.
    function testFlashloan() public {
        // No-op; compile guard only (real Aave adapter tests live in AaveFlashloanAdapter.t.sol)
        assertTrue(true);
    }
}
