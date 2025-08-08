// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {LGPCore} from "contracts/core/LGPCore.sol";
import {EarningsEscrow} from "contracts/core/EarningsEscrow.sol";
import {Reputation} from "contracts/core/Reputation.sol";
import {FeeSplitter} from "contracts/core/FeeSplitter.sol";

contract LGPCore_AllowlistTest is Test {
    LGPCore core;
    address market = address(0x123);
    address treasury = address(0x456);
    address kettle = address(0x777);
    address user = address(0x888);

    function setUp() public {
        FeeSplitter splitter = new FeeSplitter();
        EarningsEscrow escrow = new EarningsEscrow(1 days, treasury, splitter);
        Reputation rep = new Reputation();
        core = new LGPCore(escrow, rep, splitter);
        core.setTreasury(treasury);
    }

    function _receipt() internal view returns (LGPCore.RescueReceipt memory r) {
        r = LGPCore.RescueReceipt({
            user: user,
            market: market,
            debtAsset: address(0),
            collateralAsset: address(0),
            debtRepaid: 0,
            collateralClaimed: 0,
            userPayout: 1,
            botPayout: 0,
            opportunityId: keccak256("opp")
        });
    }

    function testMarketNotAllowed() public {
        LGPCore.RescueReceipt memory r = _receipt();
        vm.prank(kettle);
        vm.expectRevert("MARKET_NOT_ALLOWED");
        core.settle{value:1}(r, bytes(""), bytes(""));
    }

    function testChainNotAllowed() public {
        core.setMarketAllowed(market, true);
        LGPCore.RescueReceipt memory r = _receipt();
        vm.prank(kettle);
        vm.expectRevert("CHAIN_NOT_ALLOWED");
        core.settle{value:1}(r, bytes(""), bytes(""));
    }
}

