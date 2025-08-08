// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract MockLendingMarket {
    uint256 public constant COLLATERAL_CLAIMED = 1e18;

    event Liquidated(address indexed user, address indexed debtAsset, address indexed collAsset, uint256 repay);

    function liquidate(address user, address debtAsset, address collAsset, uint256 repay) external returns (uint256 collateralClaimed) {
        emit Liquidated(user, debtAsset, collAsset, repay);
        return COLLATERAL_CLAIMED;
    }
}

