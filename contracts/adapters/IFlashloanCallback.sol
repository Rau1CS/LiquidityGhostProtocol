// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IFlashloanCallback {
    /// Should perform the rescue logic and ensure the adapter can repay amount+premium.
    function onFlashloan(
        address asset,
        uint256 amount,
        uint256 premium,
        bytes calldata data
    ) external returns (bool);
}
