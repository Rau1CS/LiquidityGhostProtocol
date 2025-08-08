// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {FeeSplitter} from "./FeeSplitter.sol";

/// @title EarningsEscrow
/// @notice Holds back a portion of bot earnings for a period allowing fraud proofs
contract EarningsEscrow {
    struct Hold {
        address kettle;
        uint256 amount;
        uint64 unlockAt;
        bool claimed;
    }

    mapping(bytes32 => Hold) public holds; // key: receiptHash

    uint256 public holdbackTTL;
    address public treasury;
    FeeSplitter public feeSplitter;

    event Locked(address indexed kettle, uint256 amount, bytes32 indexed receiptHash, uint64 unlockAt);
    event Released(address indexed kettle, uint256 amount, bytes32 indexed receiptHash);
    event Slashed(bytes32 indexed receiptHash, address indexed prover, uint256 toTreasury, uint256 toProver);

    constructor(uint256 _ttl, address _treasury, FeeSplitter _feeSplitter) {
        holdbackTTL = _ttl;
        treasury = _treasury;
        feeSplitter = _feeSplitter;
    }

    function lock(address kettle, uint256 amount, bytes32 receiptHash) external payable {
        require(holds[receiptHash].amount == 0, "LOCKED");
        require(msg.value == amount, "VALUE");

        uint64 unlockAt = uint64(block.timestamp + holdbackTTL);
        holds[receiptHash] = Hold({kettle: kettle, amount: amount, unlockAt: unlockAt, claimed: false});

        emit Locked(kettle, amount, receiptHash, unlockAt);
    }

    function release(bytes32 receiptHash) external {
        Hold storage h = holds[receiptHash];
        require(h.amount > 0, "NO_HOLD");
        require(!h.claimed, "CLAIMED");
        require(block.timestamp >= h.unlockAt, "LOCKED");
        h.claimed = true;
        payable(h.kettle).transfer(h.amount);
        emit Released(h.kettle, h.amount, receiptHash);
    }

    function proveFraud(bytes32 receiptHash, bytes calldata) external {
        Hold storage h = holds[receiptHash];
        require(h.amount > 0, "NO_HOLD");
        require(!h.claimed, "CLAIMED");
        h.claimed = true;

        uint256 half = h.amount / 2;
        payable(msg.sender).transfer(half);
        uint256 rest = h.amount - half;
        payable(treasury).transfer(rest);

        emit Slashed(receiptHash, msg.sender, rest, half);
    }
}

