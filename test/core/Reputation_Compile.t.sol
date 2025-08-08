// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {Reputation} from "contracts/core/Reputation.sol";

contract Reputation_CompileTest is Test {
    function testScoreZero() public {
        Reputation rep = new Reputation();
        assertEq(rep.scoreOf(address(1)), 0);
        rep.bump(address(1), true, false);
    }
}

