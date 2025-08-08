// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract Reputation {
    struct Score {
        uint64 landed;
        uint64 wasted;
        uint64 reverts;
    }

    mapping(address => Score) internal scores;

    event ScoreUpdated(address indexed kettle, uint64 landed, uint64 wasted, uint64 reverts);

    function scoreOf(address kettle) external view returns (uint64, uint64, uint64) {
        Score storage s = scores[kettle];
        return (s.landed, s.wasted, s.reverts);
    }

    function bump(address kettle, bool landedBundle, bool reverted) external {
        Score storage s = scores[kettle];
        if (landedBundle) {
            s.landed += 1;
        } else {
            s.wasted += 1;
        }
        if (reverted) s.reverts += 1;

        emit ScoreUpdated(kettle, s.landed, s.wasted, s.reverts);
    }
}

