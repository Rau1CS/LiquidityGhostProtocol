// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {AaveFlashloanAdapter} from "contracts/adapters/aave/AaveFlashloanAdapter.sol";
import {MockERC20} from "contracts/mocks/MockERC20.sol";
import {MockAavePool} from "contracts/mocks/MockAavePool.sol";
import {MockAddressesProvider} from "contracts/mocks/MockAddressesProvider.sol";
import {MockFlashCallback} from "contracts/mocks/MockFlashCallback.sol";

contract AaveFlashloanAdapterTest is Test {
    MockERC20 weth;
    MockAavePool pool;
    MockAddressesProvider provider;
    MockFlashCallback callback;
    AaveFlashloanAdapter adapter;

    function setUp() public {
        weth = new MockERC20("WETH", "WETH");
        pool = new MockAavePool();
        provider = new MockAddressesProvider(address(pool));
        callback = new MockFlashCallback();
        adapter = new AaveFlashloanAdapter(provider, address(callback));
        // seed pool with liquidity
        weth.mint(address(pool), 1e24);
    }

    function testLoanAndCallbackHappy() public {
        uint256 start = weth.balanceOf(address(pool));
        uint256 amount = 1e18;
        adapter.loanAndCallback(address(weth), amount, "");
        uint256 premium = (amount * pool.premiumBps()) / 10_000;
        assertEq(weth.balanceOf(address(pool)), start + premium, "premium added");
        assertEq(weth.allowance(address(adapter), address(pool)), 0, "allowance cleared");
    }

    function testCallbackFails() public {
        callback.setShouldSucceed(false);
        vm.expectRevert(AaveFlashloanAdapter.CallbackFailed.selector);
        adapter.loanAndCallback(address(weth), 1e18, "");
    }

    function testUnauthorizedPool() public {
        vm.expectRevert(AaveFlashloanAdapter.NotPool.selector);
        adapter.executeOperation(address(weth), 1, 0, address(this), "");
    }
}
