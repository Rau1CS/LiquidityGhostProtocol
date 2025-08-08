// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {BridgeAdapterMock} from "contracts/adapters/BridgeAdapterMock.sol";
import {MockERC20} from "contracts/mocks/MockERC20.sol";
import {MockLendingMarket} from "contracts/mocks/MockLendingMarket.sol";
import {EarningsEscrow} from "contracts/core/EarningsEscrow.sol";
import {Reputation} from "contracts/core/Reputation.sol";
import {FeeSplitter} from "contracts/core/FeeSplitter.sol";
import {LGPCore} from "contracts/core/LGPCore.sol";
import {IBridgeAdapter} from "contracts/adapters/IBridgeAdapter.sol";

contract CrossChain_RescueTest is Test {
    BridgeAdapterMock bridge;
    MockERC20 weth;
    EarningsEscrow escrow;
    Reputation rep;
    FeeSplitter splitter;
    LGPCore core;
    MockLendingMarket market;

    address user = address(0x123);
    address treasury = address(0xdead);
    uint16 constant DST_CHAIN_ID = 1;

    function setUp() public {
        bridge = new BridgeAdapterMock();
        weth = new MockERC20("WETH", "WETH");
        splitter = new FeeSplitter();
        escrow = new EarningsEscrow(1 days, treasury, splitter);
        rep = new Reputation();
        core = new LGPCore(escrow, rep, splitter);
        market = new MockLendingMarket();
        core.setTreasury(treasury);
        core.setMarketAllowed(address(market), true);
        core.setChainAllowed(block.chainid, true);
        vm.deal(address(this), 10 ether);
        weth.mint(address(this), 1 ether);
        weth.approve(address(bridge), type(uint256).max);
    }

    function _settle(uint256 userAmt, uint256 botAmt, bytes32 opp) internal {
        LGPCore.RescueReceipt memory r = LGPCore.RescueReceipt({
            user: user,
            market: address(market),
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
        core.settle{value: saved}(r, bytes(""), abi.encode(block.chainid));
    }

    function testRescueHappyPath() public {
        bytes memory memo = bytes("memo");
        bytes32 guid = bridge.send(address(weth), 1 ether, DST_CHAIN_ID, memo);
        vm.warp(block.timestamp + 10);
        vm.expectEmit(true, false, false, true);
        emit IBridgeAdapter.Received(address(weth), 1 ether, 0, guid, bytes("payload"));
        bridge.deliver(guid, bytes("payload"));
        market.liquidate(user, address(0), address(0), 0);
        _settle(5 ether / 10, 4 ether / 10, guid);
    }

    function testTimeoutFallback() public {
        bytes32 guid = bridge.send(address(weth), 1 ether, DST_CHAIN_ID, bytes("memo"));
        vm.warp(block.timestamp + 1000);
        (,,,, bool delivered,) = bridge.packets(guid);
        assertFalse(delivered, "should not be delivered");
    }
}
