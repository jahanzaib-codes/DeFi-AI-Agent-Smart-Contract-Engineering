// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/**
 * @title EVMStorageLayout
 * @author Jahanzaib (@jahanzaib-codes)
 * @notice Demonstrates EVM storage slot alignment, packing efficiency, and assembly memory loads.
 * @dev Understanding slot packing is critical for reducing cold SLOAD (2100 gas) and SSTORE operations.
 */
contract EVMStorageLayout {
    // --- STORAGE SLOT 0: 32 BYTES PACKED ---
    // In unoptimized code, placing uint256 between address and bool wastes two full 32-byte slots (64 bytes).
    // Here, address (20 bytes) + uint64 (8 bytes) + uint32 (4 bytes) = 32 bytes packed into exactly Slot 0.
    address public immutable protocolTreasury; // immutable: stored in runtime bytecode, costs 0 storage slots
    address public operator;                   // 20 bytes - Slot 0
    uint64  public lastExecutionTimestamp;     // 8 bytes  - Slot 0
    uint32  public executionCounter;           // 4 bytes  - Slot 0 (Total 32 bytes: 0 wasted padding)

    // --- STORAGE SLOT 1: 32 BYTES ---
    uint256 public cumulativeVolumeUSD;

    // --- STORAGE SLOT 2: 32 BYTES PACKED ---
    uint128 public maxSingleTradeLimit;        // 16 bytes - Slot 2
    uint64  public cooldownDuration;           // 8 bytes  - Slot 2
    bool    public isEmergencyPaused;          // 1 byte   - Slot 2
    // 7 bytes free in Slot 2 for future upgrades without storage collision

    // --- CUSTOM ERRORS (Gas saver: saves ~240 gas vs require strings) ---
    error UnauthorizedCaller(address caller);
    error CooldownActive(uint256 remainingSeconds);
    error VolumeLimitExceeded(uint256 attempted, uint256 maxAllowed);
    error SystemPaused();

    event ParametersUpdated(address indexed operator, uint128 maxLimit, uint64 cooldown);
    event ExecutionLogged(uint32 indexed count, uint256 volume);

    modifier onlyOperator() {
        if (msg.sender != operator) revert UnauthorizedCaller(msg.sender);
        _;
    }

    modifier whenNotPaused() {
        if (isEmergencyPaused) revert SystemPaused();
        _;
    }

    constructor(address _treasury, address _operator, uint128 _initialMaxLimit) {
        require(_treasury != address(0), "Invalid treasury");
        require(_operator != address(0), "Invalid operator");
        protocolTreasury = _treasury;
        operator = _operator;
        maxSingleTradeLimit = _initialMaxLimit;
        cooldownDuration = 300; // 5 minutes default
    }

    /**
     * @notice Updates operational guardrails.
     * @dev Writing to Slot 2 modifies multiple variables in a single SSTORE (5000 gas warm instead of 20000+).
     */
    function updateGuardrails(uint128 _newMaxLimit, uint64 _newCooldown) external onlyOperator {
        maxSingleTradeLimit = _newMaxLimit;
        cooldownDuration = _newCooldown;
        emit ParametersUpdated(msg.sender, _newMaxLimit, _newCooldown);
    }

    /**
     * @notice Simulates an execution check demonstrating inline assembly calldata reading.
     * @dev Reading directly from calldata via assembly avoids copying overhead for large payload buffers.
     */
    function executeAction(uint256 tradeAmount) external whenNotPaused {
        // Enforce cooldown
        if (block.timestamp < lastExecutionTimestamp + cooldownDuration) {
            revert CooldownActive((lastExecutionTimestamp + cooldownDuration) - block.timestamp);
        }

        // Enforce volume caps
        if (tradeAmount > maxSingleTradeLimit) {
            revert VolumeLimitExceeded(tradeAmount, maxSingleTradeLimit);
        }

        // Update state in single warm slot write
        unchecked {
            executionCounter++;
            cumulativeVolumeUSD += tradeAmount;
        }
        lastExecutionTimestamp = uint64(block.timestamp);

        emit ExecutionLogged(executionCounter, tradeAmount);
    }

    /**
     * @notice Helper to read raw storage slot directly via assembly.
     */
    function readRawSlot(uint256 slot) external view returns (bytes32 value) {
        assembly {
            value := sload(slot)
        }
    }
}
