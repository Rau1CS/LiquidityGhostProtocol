// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {EarningsEscrow} from "contracts/core/EarningsEscrow.sol";
import {FeeSplitter} from "contracts/core/FeeSplitter.sol";

contract EarningsEscrow_CompileTest is Test {
    function testCalls() public {
        FeeSplitter splitter = new FeeSplitter();
        EarningsEscrow escrow = new EarningsEscrow(1 days, address(this), splitter);
        bytes32 id = keccak256("test");
        escrow.lock{value: 1 ether}(address(1), 1 ether, id);
        vm.warp(block.timestamp + 1 days + 1);
        escrow.release(id);
        escrow.proveFraud(id, bytes("proof"));
    }
}

