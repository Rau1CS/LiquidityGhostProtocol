// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract EarningsEscrow {
    struct Locked {
        address user;
        uint256 amount;
        uint64 unlockTime;
    }

    mapping(bytes32 => Locked) public locks;

    event Locked(bytes32 indexed id, address indexed user, uint256 amount);
    event Released(bytes32 indexed id, address indexed user, uint256 amount);
    event FraudProven(bytes32 indexed id, bytes proof);

    function lock(address user, uint256 amount, bytes32 id) external {
        emit Locked(id, user, amount);
    }

    function release(bytes32 id) external {
        Locked storage l = locks[id];
        emit Released(id, l.user, l.amount);
    }

    function proveFraud(bytes32 id, bytes calldata proof) external {
        emit FraudProven(id, proof);
    }
}

