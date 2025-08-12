// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";

import {LGPCore} from "../../contracts/core/LGPCore.sol";
import {EarningsEscrow} from "../../contracts/core/EarningsEscrow.sol";
import {Reputation} from "../../contracts/core/Reputation.sol";
import {FeeSplitter} from "../../contracts/core/FeeSplitter.sol";

contract LGPCore_FeesTest is Test {
    LGPCore internal core;
    EarningsEscrow internal esc;
    Reputation internal rep;
    FeeSplitter internal fs;

    address payable internal treasury = payable(address(0x100));
    address payable internal kettle   = payable(address(0x400));
    address payable internal user     = payable(address(0x300));
    address internal market = address(0x200);

    function setUp() public {
        fs = new FeeSplitter();
        esc = new EarningsEscrow(86401, treasury, fs);
        rep = new Reputation();

        core = new LGPCore(esc, rep, fs);
        core.setTreasury(treasury);

        // open gates so we exercise fee math
        core.setMarketAllowed(market, true);
        core.setChainAllowed(block.chainid, true);

        // zero balances so delta assertions are clean
        vm.deal(kettle, 0);
        vm.deal(user, 0);
        vm.deal(treasury, 0);
    }

    function _r(uint256 u, uint256 b, bytes32 id) internal view returns (LGPCore.RescueReceipt memory r) {
        r.user = user;
        r.market = market;
        r.debtAsset = address(0);
        r.collateralAsset = address(0);
        r.debtRepaid = 0;
        r.collateralClaimed = 0;
        r.userPayout = u;
        r.botPayout = b;
        r.opportunityId = id;
    }

    function testSmallS() public {
        // S = 25 => user 13, bot 7, holdback 2, fee 3
        uint256 S = 25;
        LGPCore.RescueReceipt memory r = _r(13, 7, keccak256("s"));

        vm.deal(kettle, S);
        uint256 u0 = user.balance;
        uint256 k0 = kettle.balance;
        uint256 t0 = treasury.balance;

        vm.prank(kettle);
        core.settle{value: S}(r, "", "");

        uint16 feeBps = core.protocolFeeBps();
        uint16 hbBps  = core.holdbackBps();
        uint256 fee = (S * feeBps) / 10_000;
        uint256 botGross = S - fee;
        uint256 holdback = (botGross * hbBps) / 10_000;

        assertEq(user.balance - u0, r.userPayout);
        assertEq(kettle.balance - (k0 - S), r.botPayout);
        assertEq(treasury.balance - t0, fee);
        assertEq(r.userPayout + r.botPayout + holdback + fee, S);
    }

    function testMediumS() public {
        // S = 120 => user 60, bot 32, holdback 10, fee 18
        uint256 S = 120;
        LGPCore.RescueReceipt memory r = _r(60, 32, keccak256("m"));

        vm.deal(kettle, S);
        uint256 u0 = user.balance;
        uint256 k0 = kettle.balance;
        uint256 t0 = treasury.balance;

        vm.prank(kettle);
        core.settle{value: S}(r, "", "");

        uint16 feeBps = core.protocolFeeBps();
        uint16 hbBps  = core.holdbackBps();
        uint256 fee = (S * feeBps) / 10_000;
        uint256 botGross = S - fee;
        uint256 holdback = (botGross * hbBps) / 10_000;

        assertEq(user.balance - u0, r.userPayout);
        assertEq(kettle.balance - (k0 - S), r.botPayout);
        assertEq(treasury.balance - t0, fee);
        assertEq(r.userPayout + r.botPayout + holdback + fee, S);
    }

    function testZeroSReverts() public {
        LGPCore.RescueReceipt memory r = _r(0, 0, keccak256("z"));
        vm.prank(kettle);
        vm.expectRevert();
        core.settle{value: 0}(r, "", "");
    }
}
