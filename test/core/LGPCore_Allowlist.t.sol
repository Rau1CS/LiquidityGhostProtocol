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
        esc = new EarningsEscrow();
        rep = new Reputation();
        fs = new FeeSplitter();

        core = new LGPCore(address(esc), address(rep), address(fs), treasury);

        // Fund kettle so settle{value:...} doesn’t OutOfFunds before revert checks
        vm.deal(kettle, 1 ether);
    }

    function _r() internal view returns (LGPCore.RescueReceipt memory r) {
        r.user = user;
        r.market = market;
        r.debtAsset = address(0);
        r.collateralAsset = address(0);
        r.debtRepaid = 0;
        r.collateralClaimed = 0;
        r.userPayout = 1; // 1 wei to ensure non-zero path
        r.botPayout = 0;
        r.opportunityId = keccak256("op");
    }

    function testMarketNotAllowed() public {
        // market is NOT allowlisted
        vm.prank(kettle);
        vm.expectRevert(LGPCore.MARKET_NOT_ALLOWED.selector);
        core.settle{value: 1}(_r(), "", "");
    }

    function testChainNotAllowed() public {
        // Allow the market but not the chain so CHAIN_NOT_ALLOWED triggers
        core.setMarketAllowed(market, true);

        vm.prank(kettle);
        vm.expectRevert(LGPCore.CHAIN_NOT_ALLOWED.selector);
        // proofs empty -> core should treat srcChain as disallowed in this test config
        core.settle{value: 1}(_r(), "", "");
    }
}
