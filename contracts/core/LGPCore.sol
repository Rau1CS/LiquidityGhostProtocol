// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {EarningsEscrow} from "./EarningsEscrow.sol";
import {Reputation} from "./Reputation.sol";
import {FeeSplitter} from "./FeeSplitter.sol";

/// @notice minimal Ownable implementation
abstract contract Ownable {
    address public owner;

    error NotOwner();

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }
}

/// @notice minimal reentrancy guard
abstract contract ReentrancyGuard {
    uint256 private _status;

    constructor() {
        _status = 1;
    }

    modifier nonReentrant() {
        require(_status != 2, "REENTRANT");
        _status = 2;
        _;
        _status = 1;
    }
}

contract LGPCore is Ownable, ReentrancyGuard {
    // bps constants
    uint16 private constant BPS_DENOM = 10_000;

    // protocol configuration
    uint16 private PROTOCOL_FEE_BPS = 1500; // 15%
    uint16 private HOLD_BACK_BPS = 1000; // 10%
    uint256 public holdbackTTL = 24 hours;
    address public treasury;

    // allowlists
    mapping(address => bool) public marketAllowlist;
    mapping(uint256 => bool) public chainAllowlist;

    // external contracts
    EarningsEscrow public immutable escrow;
    Reputation public immutable rep;
    FeeSplitter public immutable feeSplitter;

    struct RescueReceipt {
        address user;
        address market;
        address debtAsset;
        address collateralAsset;
        uint256 debtRepaid;
        uint256 collateralClaimed;
        uint256 userPayout; // after protocol fee
        uint256 botPayout; // after holdback
        bytes32 opportunityId;
    }

    event RescueExecuted(bytes32 indexed opportunityId, address indexed kettle, address indexed user, uint256 savedValue);

    constructor(EarningsEscrow _escrow, Reputation _rep, FeeSplitter _feeSplitter) {
        escrow = _escrow;
        rep = _rep;
        feeSplitter = _feeSplitter;
    }

    // ----------------- admin -----------------
    function setFeeBps(uint16 bps) external onlyOwner {
        require(bps < BPS_DENOM, "BPS");
        PROTOCOL_FEE_BPS = bps;
    }

    function setHoldbackBps(uint16 bps) external onlyOwner {
        require(bps < BPS_DENOM, "BPS");
        HOLD_BACK_BPS = bps;
    }

    function setHoldbackTTL(uint256 ttl) external onlyOwner {
        holdbackTTL = ttl;
    }

    function setTreasury(address t) external onlyOwner {
        treasury = t;
    }

    function setMarketAllowed(address market, bool allowed) external onlyOwner {
        marketAllowlist[market] = allowed;
    }

    function setChainAllowed(uint256 chainId, bool allowed) external onlyOwner {
        chainAllowlist[chainId] = allowed;
    }

    // ----------------- views -----------------
    function protocolFeeBps() external view returns (uint16) {
        return PROTOCOL_FEE_BPS;
    }

    function holdbackBps() external view returns (uint16) {
        return HOLD_BACK_BPS;
    }

    // ----------------- core logic -----------------
    function settle(
        RescueReceipt calldata r,
        bytes calldata kettleAttestation,
        bytes calldata proofs
    ) external payable nonReentrant {
        require(marketAllowlist[r.market], "MARKET_NOT_ALLOWED");

        uint256 srcChainId = block.chainid;
        if (proofs.length >= 32) {
            srcChainId = abi.decode(proofs, (uint256));
        }
        require(chainAllowlist[srcChainId], "CHAIN_NOT_ALLOWED");

        uint256 net = r.userPayout + r.botPayout;
        require(net > 0, "ZERO_VALUE");

        // holdback first - independent of protocol fee
        uint256 holdback = (net * HOLD_BACK_BPS) / (BPS_DENOM - HOLD_BACK_BPS);
        uint256 preFee = net + holdback;
        uint256 fee = (preFee * PROTOCOL_FEE_BPS) / (BPS_DENOM - PROTOCOL_FEE_BPS);
        uint256 savedValue = preFee + fee;

        require(
            r.userPayout + r.botPayout + holdback + fee == savedValue ||
                r.userPayout + r.botPayout + holdback + fee + 1 == savedValue,
            "BAD_SPLIT"
        );

        require(msg.value == savedValue, "INSUFFICIENT_VALUE");

        // transfers
        payable(r.user).transfer(r.userPayout);
        payable(msg.sender).transfer(r.botPayout);

        bytes32 receiptHash = keccak256(abi.encode(r, kettleAttestation));
        escrow.lock{value: holdback}(msg.sender, holdback, receiptHash);

        if (fee > 0) {
            payable(treasury).transfer(fee);
        }

        rep.bump(msg.sender, true, false);

        emit RescueExecuted(r.opportunityId, msg.sender, r.user, savedValue);
    }
}

