// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IPool, IPoolAddressesProvider, IFlashLoanSimpleReceiver} from "./IAaveV3.sol";
import {IFlashloanCallback} from "../IFlashloanCallback.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

contract AaveFlashloanAdapter is IFlashLoanSimpleReceiver {
    error NotPool();
    error CallbackFailed();

    IPoolAddressesProvider public immutable addressesProvider;
    address public immutable callback;
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "NOT_OWNER");
        _;
    }

    constructor(IPoolAddressesProvider _provider, address _callback) {
        addressesProvider = _provider;
        callback = _callback;
        owner = msg.sender;
    }

    function setOwner(address n) external onlyOwner {
        owner = n;
    }

    function pool() public view returns (IPool) {
        return IPool(addressesProvider.getPool());
    }

    function loanAndCallback(address asset, uint256 amount, bytes calldata data) external {
        pool().flashLoanSimple(address(this), asset, amount, data, 0);
    }

    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {
        if (msg.sender != address(pool())) revert NotPool();

        bool ok = IFlashloanCallback(callback).onFlashloan(asset, amount, premium, params);
        if (!ok) revert CallbackFailed();

        IERC20(asset).approve(msg.sender, amount + premium);
        return true;
    }
}
