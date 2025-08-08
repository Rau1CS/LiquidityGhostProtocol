// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {Reputation} from "contracts/core/Reputation.sol";

contract Reputation_UpdateTest is Test {
    function testBumps() public {
        Reputation rep = new Reputation();
        address kettle = address(0xABC);

        (uint64 l,uint64 w,uint64 r) = rep.scoreOf(kettle);
        assertEq(l,0); assertEq(w,0); assertEq(r,0);

        rep.bump(kettle, true, false);
        (l,w,r) = rep.scoreOf(kettle);
        assertEq(l,1); assertEq(w,0); assertEq(r,0);

        rep.bump(kettle, false, true);
        (l,w,r) = rep.scoreOf(kettle);
        assertEq(l,1); assertEq(w,1); assertEq(r,1);
    }
}

