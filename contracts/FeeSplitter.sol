// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract FeeSplitter {
    address public immutable protocol;

    event FeeDistributed(address indexed protocol, address indexed executor, uint256 amount);

    constructor(address _protocol) {
        protocol = _protocol;
    }

    function split(uint256 amount, address executor) external {
        emit FeeDistributed(protocol, executor, amount);
    }
}
