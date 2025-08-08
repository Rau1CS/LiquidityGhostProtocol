// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {Reputation} from "contracts/core/Reputation.sol";

contract Reputation_CompileTest is Test {
    function testScoreZero() public {
        Reputation rep = new Reputation();
        (uint64 l, uint64 w, uint64 r) = rep.scoreOf(address(1));
        assertEq(l, 0); assertEq(w,0); assertEq(r,0);
        rep.bump(address(1), true, false);
    }
}

