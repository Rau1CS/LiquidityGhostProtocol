// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IFlashloanAdapter} from "./IFlashloanAdapter.sol";

contract FlashloanAdapterMock is IFlashloanAdapter {
    function loanAndCallback(address token, uint256 amount, bytes calldata data) external override {
        emit Flashloan(token, amount);
    }
}
