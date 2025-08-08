// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IFlashloanAdapter {
    event Flashloan(address indexed token, uint256 amount);

    function loanAndCallback(address token, uint256 amount, bytes calldata data) external;
}
