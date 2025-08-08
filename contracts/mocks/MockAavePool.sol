// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IPool, IFlashLoanSimpleReceiver} from "contracts/adapters/aave/IAaveV3.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

contract MockAavePool is IPool {
    uint256 public premiumBps = 9; // 0.09%

    function setPremiumBps(uint256 bps) external {
        premiumBps = bps;
    }

    function deposit(address asset, uint256 amount) external {
        IERC20(asset).transferFrom(msg.sender, address(this), amount);
    }

    function flashLoanSimple(
        address receiverAddress,
        address asset,
        uint256 amount,
        bytes calldata params,
        uint16
    ) external override {
        uint256 premium = (amount * premiumBps) / 10_000;
        IERC20(asset).transfer(receiverAddress, amount);
        IFlashLoanSimpleReceiver(receiverAddress).executeOperation(
            asset,
            amount,
            premium,
            msg.sender,
            params
        );
        IERC20(asset).transferFrom(receiverAddress, address(this), amount + premium);
    }
}
