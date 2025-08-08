// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IFlashloanAdapter {
    event Flashloan(address indexed token, uint256 amount, address indexed to);

    function flashloan(address token, uint256 amount, address to, bytes calldata data) external;
}

