// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract FeeSplitter {
    mapping(address => mapping(address => uint256)) public balances;

    event Withdrawn(address indexed token, address indexed to, uint256 amount);

    function withdraw(address token, address to, uint256 amt) external {
        emit Withdrawn(token, to, amt);
    }
}

