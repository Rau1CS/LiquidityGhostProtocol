// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";

import {LGPCore} from "../../contracts/core/LGPCore.sol";
import {EarningsEscrow} from "../../contracts/core/EarningsEscrow.sol";
import {Reputation} from "../../contracts/core/Reputation.sol";
import {FeeSplitter} from "../../contracts/core/FeeSplitter.sol";

contract LGPCore_AllowlistTest is Test {
    LGPCore internal core;
    EarningsEscrow internal esc;
    Reputation internal rep;
    FeeSplitter internal fs;

    address internal treasury = address(0x100);
    address internal kettle = address(0x777);
    address internal user = address(0x888);
    address internal market = address(0x123);

    function setUp() public {
        fs = new FeeSplitter();
        // EarningsEscrow constructor: (ttl, treasury, feeSplitter)
        esc = new EarningsEscrow(86401, treasury, fs);
        rep = new Reputation();

        // LGPCore expects (escrow, reputation, feeSplitter). Treasury set via setter.
        core = new LGPCore(esc, rep, fs);
        core.setTreasury(treasury);

        // Fund the prank caller so it can attach value
        vm.deal(kettle, 1 ether);
    }

    function _r() internal view returns (LGPCore.RescueReceipt memory r) {
        r.user = user;
        r.market = market;
        r.debtAsset = address(0);
        r.collateralAsset = address(0);
        r.debtRepaid = 0;
        r.collateralClaimed = 0;
        r.userPayout = 1; // make non-zero
        r.botPayout = 0;
        r.opportunityId = keccak256("op");
    }

    function testMarketNotAllowed() public {
        // market NOT allowlisted
        vm.prank(kettle);
        vm.expectRevert(); // custom error name not exported, just check revert
        core.settle{value: 1}(_r(), "", "");
    }

    function testChainNotAllowed() public {
        // Allow market but not chain, so chain guard triggers
        core.setMarketAllowed(market, true);

        vm.prank(kettle);
        vm.expectRevert();
        core.settle{value: 1}(_r(), "", "");
    }
}
