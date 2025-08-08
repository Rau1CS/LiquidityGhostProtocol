// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract EarningsEscrow {
    struct Holdback {
        uint256 amount;
        uint256 release;
    }

    mapping(address => Holdback) public holdbacks;

    event HoldbackDeposited(address indexed user, uint256 amount, uint256 release);
    event HoldbackReleased(address indexed user, uint256 amount);

    function deposit(address user, uint256 amount, uint256 ttl) external {
        Holdback storage h = holdbacks[user];
        h.amount += amount;
        h.release = block.timestamp + ttl;
        emit HoldbackDeposited(user, amount, h.release);
    }

    function release() external {
        Holdback storage h = holdbacks[msg.sender];
        require(h.amount > 0 && block.timestamp >= h.release, "not releasable");
        uint256 amount = h.amount;
        delete holdbacks[msg.sender];
        emit HoldbackReleased(msg.sender, amount);
    }
}
