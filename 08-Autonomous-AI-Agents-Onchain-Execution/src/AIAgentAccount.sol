// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/**
 * @title AIAgentAccount
 * @author Jahanzaib (@jahanzaib-codes)
 * @notice ERC-4337 Compatible Smart Account designed for Autonomous AI Agent execution.
 *         Implements time-bounded Session Keys and granular execution whitelists.
 */
contract AIAgentAccount {
    address public immutable owner;

    struct SessionKeyPolicy {
        bool isValid;
        uint64 validUntil;
        uint128 dailySpendLimit;
        uint128 spentToday;
        uint64 lastResetDay;
    }

    // Session Key Address -> Policy
    mapping(address => SessionKeyPolicy) public sessionKeys;
    // Authorized target contracts (e.g. Aerodrome Router, Uniswap V3 Pool)
    mapping(address => bool) public whitelistedTargets;

    error Unauthorized();
    error SessionKeyExpired();
    error TargetNotWhitelisted(address target);
    error DailyLimitExceeded(uint256 attempted, uint256 remaining);
    error ExecutionFailed();

    event SessionKeyRegistered(address indexed sessionKey, uint64 validUntil, uint128 dailyLimit);
    event TargetWhitelisted(address indexed target, bool status);
    event ExecutedByAgent(address indexed agent, address indexed target, uint256 value);

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    constructor(address _owner) {
        require(_owner != address(0), "Zero address");
        owner = _owner;
    }

    function setWhitelistedTarget(address target, bool status) external onlyOwner {
        whitelistedTargets[target] = status;
        emit TargetWhitelisted(target, status);
    }

    function registerSessionKey(
        address sessionKey,
        uint64 validUntil,
        uint128 dailySpendLimit
    ) external onlyOwner {
        require(sessionKey != address(0), "Invalid key");
        require(validUntil > block.timestamp, "Invalid expiration");

        sessionKeys[sessionKey] = SessionKeyPolicy({
            isValid: true,
            validUntil: validUntil,
            dailySpendLimit: dailySpendLimit,
            spentToday: 0,
            lastResetDay: uint64(block.timestamp / 86400)
        });

        emit SessionKeyRegistered(sessionKey, validUntil, dailySpendLimit);
    }

    /**
     * @notice Executed directly by an Autonomous AI Agent via its scoped session key.
     */
    function executeFromAgent(
        address target,
        uint256 value,
        bytes calldata data
    ) external returns (bytes memory returnData) {
        SessionKeyPolicy storage policy = sessionKeys[msg.sender];

        // 1. Authenticate Session Key
        if (!policy.isValid || block.timestamp > policy.validUntil) {
            revert SessionKeyExpired();
        }

        // 2. Validate Whitelisted Target Contract
        if (!whitelistedTargets[target]) {
            revert TargetNotWhitelisted(target);
        }

        // 3. Enforce Daily Velocity Spend Limit
        uint64 currentDay = uint64(block.timestamp / 86400);
        if (currentDay > policy.lastResetDay) {
            policy.spentToday = 0;
            policy.lastResetDay = currentDay;
        }

        if (policy.spentToday + value > policy.dailySpendLimit) {
            revert DailyLimitExceeded(value, policy.dailySpendLimit - policy.spentToday);
        }

        policy.spentToday += uint128(value);

        // 4. Dispatch Call
        bool success;
        (success, returnData) = target.call{value: value}(data);
        if (!success) revert ExecutionFailed();

        emit ExecutedByAgent(msg.sender, target, value);
    }

    receive() external payable {}
}
