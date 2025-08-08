// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract Reputation {
    mapping(address => uint256) public score;

    event ReputationUpdated(address indexed user, uint256 newScore);

    function increment(address user) external {
        score[user] += 1;
        emit ReputationUpdated(user, score[user]);
    }
}
