// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {EarningsEscrow} from "../../contracts/core/EarningsEscrow.sol";
import {FeeSplitter} from "../../contracts/core/FeeSplitter.sol";

contract EarningsEscrow_CompileTest is Test {
    EarningsEscrow internal esc;
    FeeSplitter internal fs;
    address payable internal kettle;

    function setUp() public {
        fs = new FeeSplitter();
        esc = new EarningsEscrow();
        kettle = payable(makeAddr("kettle"));
    }

    function testCalls() public {
        // Lock → warp → release to a PAYABLE EOA (not a precompile)
        bytes32 receipt = keccak256("r1");
        vm.deal(address(this), 1 ether);
        esc.lock{value: 1 ether}(kettle, 1 ether, receipt);

        vm.warp(block.timestamp + 86401);
        uint256 before = kettle.balance;
        esc.release(receipt);
        assertEq(kettle.balance - before, 1 ether);
    }
}
