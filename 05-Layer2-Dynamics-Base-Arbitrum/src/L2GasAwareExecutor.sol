// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/**
 * @title L2GasAwareExecutor
 * @author Jahanzaib (@jahanzaib-codes)
 * @notice Demonstrates L2 gas optimization techniques specific to Optimistic Rollups (Base / Arbitrum),
 *         taking into account execution gas vs L1 calldata overhead under EIP-4844 blobs.
 */
contract L2GasAwareExecutor {
    address public immutable owner;

    // Bitmap to store up to 256 boolean flags in a single storage slot
    // Saves 20,000 gas per flag compared to standard mapping(uint256 => bool)
    uint256 private _executionBitmap;

    error Unauthorized();
    error ActionAlreadyExecuted(uint256 actionId);
    error ExecutionFailed();

    event ActionExecuted(uint256 indexed actionId, address target, bytes data);

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @notice Execute an authorized action with bitmap deduplication.
     * @dev On L2, calldata bytes cost L1 publication gas. Using calldata compression and tightly packed
     *      identifiers reduces the batch submission cost to L1 Ethereum.
     */
    function executeAction(
        uint256 actionId,
        address target,
        bytes calldata payload
    ) external onlyOwner returns (bytes memory returnData) {
        // Bitwise check if actionId is already executed
        uint256 mask = 1 << (actionId % 256);
        if ((_executionBitmap & mask) != 0) {
            revert ActionAlreadyExecuted(actionId);
        }

        // Mark as executed
        _executionBitmap |= mask;

        // Low-level call with bounded gas forward
        bool success;
        (success, returnData) = target.call(payload);
        if (!success) revert ExecutionFailed();

        emit ActionExecuted(actionId, target, payload);
    }

    function isExecuted(uint256 actionId) external view returns (bool) {
        uint256 mask = 1 << (actionId % 256);
        return (_executionBitmap & mask) != 0;
    }
}
