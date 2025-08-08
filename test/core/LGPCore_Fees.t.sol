// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {LGPCore} from "contracts/core/LGPCore.sol";
import {EarningsEscrow} from "contracts/core/EarningsEscrow.sol";
import {Reputation} from "contracts/core/Reputation.sol";
import {FeeSplitter} from "contracts/core/FeeSplitter.sol";

contract LGPCore_FeesTest is Test {
    LGPCore core;
    EarningsEscrow escrow;
    Reputation rep;
    FeeSplitter splitter;
    address treasury = address(0x100);
    address market = address(0x200);
    address user = address(0x300);
    address kettle = address(0x400);

    function setUp() public {
        splitter = new FeeSplitter();
        escrow = new EarningsEscrow(1 days, treasury, splitter);
        rep = new Reputation();
        core = new LGPCore(escrow, rep, splitter);

        core.setTreasury(treasury);
        core.setMarketAllowed(market, true);
        core.setChainAllowed(block.chainid, true);

        vm.deal(kettle, 10 ether);
    }

    function _settle(uint256 userAmt, uint256 botAmt, bytes32 opp) internal {
        LGPCore.RescueReceipt memory r = LGPCore.RescueReceipt({
            user: user,
            market: market,
            debtAsset: address(0),
            collateralAsset: address(0),
            debtRepaid: 0,
            collateralClaimed: 0,
            userPayout: userAmt,
            botPayout: botAmt,
            opportunityId: opp
        });

        uint16 hBps = core.holdbackBps();
        uint16 fBps = core.protocolFeeBps();
        uint256 net = userAmt + botAmt;
        uint256 holdback = (net * hBps) / (10_000 - hBps);
        uint256 preFee = net + holdback;
        uint256 fee = (preFee * fBps) / (10_000 - fBps);
        uint256 saved = preFee + fee;

        vm.prank(kettle);
        core.settle{value: saved}(r, bytes(""), bytes(""));

        assertEq(user.balance, userAmt);
        assertEq(kettle.balance, botAmt);
        assertEq(address(escrow).balance, holdback);
        assertEq(treasury.balance, fee);

        bytes32 receiptHash = keccak256(abi.encode(r, bytes("")));
        (address hKettle, uint256 hAmt,, bool claimed) = escrow.holds(receiptHash);
        assertEq(hKettle, kettle);
        assertEq(hAmt, holdback);
        assertFalse(claimed);

        (uint64 landed,,) = rep.scoreOf(kettle);
        assertEq(landed, 1);
    }

    function testSmallS() public {
        _settle(13, 7, keccak256("opp1"));
    }

    function testMediumS() public {
        _settle(60, 32, keccak256("opp2"));
    }

    function testZeroSReverts() public {
        LGPCore.RescueReceipt memory r = LGPCore.RescueReceipt({
            user: user,
            market: market,
            debtAsset: address(0),
            collateralAsset: address(0),
            debtRepaid: 0,
            collateralClaimed: 0,
            userPayout: 0,
            botPayout: 0,
            opportunityId: keccak256("opp0")
        });
        vm.prank(kettle);
        vm.expectRevert("ZERO_VALUE");
        core.settle(r, bytes(""), bytes(""));
    }
}

