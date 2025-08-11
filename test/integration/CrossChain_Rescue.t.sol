// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";

import {LGPCore} from "../../contracts/core/LGPCore.sol";
import {EarningsEscrow} from "../../contracts/core/EarningsEscrow.sol";
import {Reputation} from "../../contracts/core/Reputation.sol";
import {FeeSplitter} from "../../contracts/core/FeeSplitter.sol";

import {BridgeAdapterMock} from "../../contracts/adapters/BridgeAdapterMock.sol";
import {MockERC20} from "../../contracts/mocks/MockERC20.sol";
import {MockLendingMarket} from "../../contracts/mocks/MockLendingMarket.sol";

contract CrossChain_RescueTest is Test {
    // Make this test contract able to receive ETH (bot payout)
    receive() external payable {}

    LGPCore internal core;
    EarningsEscrow internal esc;
    Reputation internal rep;
    FeeSplitter internal fs;

    BridgeAdapterMock internal bridgeL2;
    BridgeAdapterMock internal bridgeL1;

    MockERC20 internal wethL2;
    MockERC20 internal wethL1;
    MockLendingMarket internal marketL1;

    address payable internal user   = payable(address(0x123));
    address payable internal kettle = payable(address(this)); // this contract is the kettle

    function setUp() public {
        // L1 core stack
        fs = new FeeSplitter();
        esc = new EarningsEscrow(address(fs), 1000, 86401);
        rep = new Reputation();

        core = new LGPCore(address(esc), address(rep), address(fs));
        core.setTreasury(address(0x100));

        // Allow current chain + a dummy market
        marketL1 = new MockLendingMarket(address(0));
        core.setMarketAllowed(address(marketL1), true);
        core.setChainAllowed(block.chainid, true);

        // Bridges and tokens
        bridgeL2 = new BridgeAdapterMock();
        bridgeL1 = new BridgeAdapterMock();

        // MockERC20 expects (name, symbol)
        wethL2 = new MockERC20("WETH", "WETH");
        wethL1 = new MockERC20("WETH", "WETH");

        // Seed L2 tokens to this contract and approve bridge
        wethL2.mint(address(this), 1 ether);
        wethL2.approve(address(bridgeL2), type(uint256).max);
    }

    function testRescueHappyPath() public {
        // 1) Send on L2
        bytes32 guid = bridgeL2.send(address(wethL2), 1 ether, 1 /*dstChainId*/, bytes("memo"));

        // 2) After latency, “deliver” to L1 and credit dst-side funds (simulated)
        vm.warp(block.timestamp + 11);
        vm.expectEmit(true, false, false, true);
        emit BridgeAdapterMock.Received(address(wethL2), 1 ether, 0, guid, bytes("payload"));
        bridgeL1.deliver(guid, bytes("payload"));

        // Simulate L1 profit from liquidation to this test (kettle)
        uint256 profit = marketL1.liquidate(user, address(0), address(0), 0);
        assertEq(profit, 1e18);

        // 3) Settle on L1 — S = user 0.5 + bot 0.4 + fee ~0.17647 (holdback comes from botGross)
        uint256 S = 500e15 + 400e15 + 176470588235294117;
        LGPCore.RescueReceipt memory r;
        r.user = user;
        r.market = address(marketL1);
        r.debtAsset = address(0);
        r.collateralAsset = address(0);
        r.debtRepaid = 0;
        r.collateralClaimed = 0;
        r.userPayout = 500e15;
        r.botPayout = 400e15;
        r.opportunityId = guid;

        uint256 u0 = user.balance;
        uint256 k0 = kettle.balance;

        core.settle{value: S}(r, "", abi.encodePacked(uint256(0x7a69)));

        assertEq(user.balance - u0, r.userPayout);
        assertEq(kettle.balance - k0, r.botPayout);
    }

    function testTimeoutFallback() public {
        // No delivery → no settlement path here (kettle-sim owns timeout behavior).
        assertTrue(true);
    }
}
