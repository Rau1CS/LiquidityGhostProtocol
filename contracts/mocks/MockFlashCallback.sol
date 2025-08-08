// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IFlashloanCallback} from "contracts/adapters/IFlashloanCallback.sol";
import {MockERC20} from "./MockERC20.sol";

contract MockFlashCallback is IFlashloanCallback {
    bool public shouldSucceed = true;

    function setShouldSucceed(bool s) external {
        shouldSucceed = s;
    }

    function onFlashloan(
        address asset,
        uint256 amount,
        uint256 premium,
        bytes calldata
    ) external override returns (bool) {
        if (!shouldSucceed) return false;
        MockERC20(asset).mint(msg.sender, amount + premium);
        return true;
    }
}
