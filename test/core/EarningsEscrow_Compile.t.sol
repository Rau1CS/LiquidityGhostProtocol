// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {EarningsEscrow} from "contracts/core/EarningsEscrow.sol";

contract EarningsEscrow_CompileTest is Test {
    function testCalls() public {
        EarningsEscrow escrow = new EarningsEscrow();
        bytes32 id = keccak256("test");
        escrow.lock(address(1), 1 ether, id);
        escrow.release(id);
        escrow.proveFraud(id, bytes("proof"));
    }
}

