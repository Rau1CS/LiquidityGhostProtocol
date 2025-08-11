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
    address payable internal kettle = payable(address(0x400));
    address payable internal user = payable(address(0x300));
    address internal market = address(0x200);

    function setUp() public {
        esc = new EarningsEscrow();
        rep = new Reputation();
        fs = new FeeSplitter();

        core = new LGPCore(address(esc), address(rep), address(fs), treasury);

        // Happy path allowlists so fee math can run
        core.setMarketAllowed(market, true);
        core.setChainAllowed(block.chainid, true);

        // Tidy balances so we can compare deltas cleanly
        vm.deal(kettle, 0);
        vm.deal(user, 0);
        vm.deal(treasury, 0);
    }

    function _r(uint256 userPayout, uint256 botPayout, bytes32 oppId) internal view returns (LGPCore.RescueReceipt memory r) {
        r.user = user;
        r.market = market;
        r.debtAsset = address(0);
        r.collateralAsset = address(0);
        r.debtRepaid = 0;
        r.collateralClaimed = 0;
        r.userPayout = userPayout;
        r.botPayout = botPayout;
        r.opportunityId = oppId;
    }

    function testSmallS() public {
        // S = 25 = user 13 + bot 7 + holdback 2 + fee 3  (with feeBps=1500, holdbackBps=1000)
        uint256 S = 25;
        LGPCore.RescueReceipt memory r = _r(13, 7, keccak256("s"));

        uint256 beforeUser = user.balance;
        uint256 beforeBot = kettle.balance;
        uint256 beforeTreasury = treasury.balance;

        vm.prank(kettle);
        core.settle{value: S}(r, "", "");

        uint16 feeBps = core.protocolFeeBps();
        uint16 hbBps = core.holdbackBps();
        uint256 fee = (S * feeBps) / 10_000;
        uint256 botGross = S - fee;
        uint256 holdback = (botGross * hbBps) / 10_000;

        assertEq(user.balance - beforeUser, r.userPayout);
        assertEq(kettle.balance - beforeBot, r.botPayout);
        assertEq(treasury.balance - beforeTreasury, fee);

        // Escrow received the holdback (we don’t read its balance here; lock event is checked in Escrow tests)
        // Accounting identity sanity
        assertEq(r.userPayout + r.botPayout + holdback + fee, S);
    }

    function testMediumS() public {
        // S = 120 = user 60 + bot 32 + holdback 10 + fee 18
        uint256 S = 120;
        LGPCore.RescueReceipt memory r = _r(60, 32, keccak256("m"));

        uint256 beforeUser = user.balance;
        uint256 beforeBot = kettle.balance;
        uint256 beforeTreasury = treasury.balance;

        vm.prank(kettle);
        core.settle{value: S}(r, "", "");

        uint16 feeBps = core.protocolFeeBps();
        uint16 hbBps = core.holdbackBps();
        uint256 fee = (S * feeBps) / 10_000;
        uint256 botGross = S - fee;
        uint256 holdback = (botGross * hbBps) / 10_000;

        assertEq(user.balance - beforeUser, r.userPayout);
        assertEq(kettle.balance - beforeBot, r.botPayout);
        assertEq(treasury.balance - beforeTreasury, fee);
        assertEq(r.userPayout + r.botPayout + holdback + fee, S);
    }

    function testZeroSReverts() public {
        LGPCore.RescueReceipt memory r = _r(0, 0, keccak256("z"));
        vm.prank(kettle);
        vm.expectRevert(); // core should reject zero-value settlements
        core.settle{value: 0}(r, "", "");
    }
}
