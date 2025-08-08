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
        emit IFlashloanAdapter.Flashloan(address(1), 1, address(this));
        mock.flashloan(address(1), 1, address(this), "");
    }

    function testBridge() public {
        BridgeAdapterMock mock = new BridgeAdapterMock();
        vm.expectEmit();
        emit IBridgeAdapter.Sent(address(1), 1, address(2));
        mock.send(address(1), 1, address(2), "");
        vm.expectEmit();
        emit IBridgeAdapter.Received(address(1), 1, address(3));
        mock.onReceive(address(1), 1, address(3), "");
    }
}

