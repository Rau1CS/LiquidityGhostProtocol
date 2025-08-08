// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {EarningsEscrow} from "contracts/core/EarningsEscrow.sol";
import {FeeSplitter} from "contracts/core/FeeSplitter.sol";

contract EarningsEscrow_FlowTest is Test {
    EarningsEscrow escrow;
    address treasury = address(0x900);
    address kettle = address(0x901);
    address prover = address(0x902);

    function setUp() public {
        FeeSplitter splitter = new FeeSplitter();
        escrow = new EarningsEscrow(1 days, treasury, splitter);
        vm.deal(address(this), 10 ether);
    }

    function testFraudSlash() public {
        bytes32 id = keccak256("hold1");
        escrow.lock{value: 1 ether}(kettle, 1 ether, id);
        vm.prank(prover);
        escrow.proveFraud(id, bytes("proof"));
        assertEq(prover.balance, 0.5 ether);
        assertEq(treasury.balance, 0.5 ether);
    }

    function testReleaseAfterTTL() public {
        bytes32 id = keccak256("hold2");
        escrow.lock{value: 1 ether}(kettle, 1 ether, id);
        vm.warp(block.timestamp + 1 days + 1);
        escrow.release(id);
        assertEq(kettle.balance, 1 ether);
        vm.expectRevert("CLAIMED");
        escrow.release(id);
    }
}

