// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {FlashloanAdapterMock} from "contracts/adapters/FlashloanAdapterMock.sol";
import {BridgeAdapterMock} from "contracts/adapters/BridgeAdapterMock.sol";
import {IFlashloanAdapter} from "contracts/adapters/IFlashloanAdapter.sol";
import {IBridgeAdapter} from "contracts/adapters/IBridgeAdapter.sol";

contract Adapters_CompileTest is Test {
    function testFlashloan() public {
        FlashloanAdapterMock mock = new FlashloanAdapterMock();
        vm.expectEmit();
        emit IFlashloanAdapter.Flashloan(address(1), 1);
        mock.loanAndCallback(address(1), 1, "");
    }

    function testBridge() public {
        BridgeAdapterMock mock = new BridgeAdapterMock();
        vm.expectEmit(true, false, false, false);
        emit IBridgeAdapter.Sent(address(1), 0, 0, bytes32(0), bytes(""));
        bytes32 guid = mock.send(address(1), 1, 2, "memo");
        vm.expectEmit(true, false, false, true);
        emit IBridgeAdapter.Received(address(1), 1, 0, guid, bytes("payload"));
        mock.deliver(guid, "payload");
    }
}
