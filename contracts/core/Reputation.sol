// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract Reputation {
    struct Counters {
        uint256 good;
        uint256 bad;
    }

    mapping(address => Counters) internal _counters;

    event Bumped(address indexed user, bool good, bool bad);

    function scoreOf(address user) external view returns (uint256) {
        return _counters[user].good;
    }

    function bump(address user, bool good, bool bad) external {
        emit Bumped(user, good, bad);
    }
}

