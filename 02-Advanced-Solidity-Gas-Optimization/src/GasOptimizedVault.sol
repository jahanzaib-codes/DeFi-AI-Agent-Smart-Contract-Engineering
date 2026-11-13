// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/**
 * @title GasOptimizedVault
 * @author Jahanzaib (@jahanzaib-codes)
 * @notice High-performance token vault implementing Yul assembly, transient storage reentrancy locks,
 *         and unchecked math for maximal gas efficiency.
 */
contract GasOptimizedVault {
    // --- TRANSIENT STORAGE REENTRANCY LOCK (EIP-1153) ---
    // Traditional reentrancy guards write to storage (SSTORE: 2,900-5,000 warm gas).
    // EIP-1153 TSTORE costs only 100 gas and clears automatically at the end of the transaction!
    bytes32 private constant REENTRANCY_SLOT = keccak256("vault.transient.reentrancy.lock");

    // --- IMMUTABLE VALUES (Zero runtime storage overhead) ---
    address public immutable assetToken;
    address public immutable emergencyAdmin;

    // --- ACCOUNT BALANCES ---
    mapping(address => uint256) private _balances;
    uint256 public totalVaultDeposits;

    // --- CUSTOM ERRORS ---
    error ReentrancyGuardTriggered();
    error ZeroDepositAmount();
    error InsufficientVaultBalance(uint256 requested, uint256 available);
    error NativeTransferFailed();
    error TokenTransferFailed();
    error UnauthorizedAdmin();

    event Deposited(address indexed account, uint256 amount);
    event Withdrawn(address indexed account, uint256 amount);

    modifier nonReentrant() {
        assembly {
            // Check transient slot
            if tload(REENTRANCY_SLOT) {
                // Revert with ReentrancyGuardTriggered() selector (0x59b58e72)
                mstore(0x00, 0x59b58e72)
                revert(0x1c, 0x04)
            }
            // Set lock flag (1)
            tstore(REENTRANCY_SLOT, 1)
        }
        _;
        assembly {
            // Clear lock flag (0)
            tstore(REENTRANCY_SLOT, 0)
        }
    }

    modifier onlyAdmin() {
        if (msg.sender != emergencyAdmin) revert UnauthorizedAdmin();
        _;
    }

    constructor(address _assetToken, address _admin) {
        require(_admin != address(0), "Invalid admin");
        assetToken = _assetToken;
        emergencyAdmin = _admin;
    }

    /**
     * @notice Deposit assets into the vault.
     * @dev Uses low-level staticcall/call for ERC20 transferFrom to handle non-standard tokens
     *      (e.g., USDT which does not return a boolean on transfer).
     */
    function deposit(uint256 amount) external nonReentrant {
        if (amount == 0) revert ZeroDepositAmount();

        // OPTIMIZATION: Update internal state before external call (Checks-Effects-Interactions)
        unchecked {
            _balances[msg.sender] += amount;
            totalVaultDeposits += amount;
        }

        // BUG FIX NOTE: Use assembly safeTransferFrom to prevent reverts on USDT / non-reverting tokens
        _safeTransferFrom(assetToken, msg.sender, address(this), amount);

        emit Deposited(msg.sender, amount);
    }

    /**
     * @notice Withdraw deposited assets.
     */
    function withdraw(uint256 amount) external nonReentrant {
        uint256 currentBalance = _balances[msg.sender];
        if (amount > currentBalance) {
            revert InsufficientVaultBalance(amount, currentBalance);
        }

        unchecked {
            _balances[msg.sender] = currentBalance - amount;
            totalVaultDeposits -= amount;
        }

        _safeTransfer(assetToken, msg.sender, amount);

        emit Withdrawn(msg.sender, amount);
    }

    /**
     * @notice Batch query balances without incurring individual SLOAD call overhead.
     */
    function getBatchBalances(address[] calldata accounts) external view returns (uint256[] memory balances) {
        uint256 length = accounts.length;
        balances = new uint256[](length);
        
        // OPTIMIZATION: Cache array length in memory and use unchecked loop counter to avoid safeMath gas penalty
        for (uint256 i = 0; i < length;) {
            balances[i] = _balances[accounts[i]];
            unchecked { ++i; }
        }
    }

    /**
     * @dev Assembly SafeTransfer helper handling return data quirks.
     */
    function _safeTransfer(address token, address to, uint256 value) internal {
        assembly {
            // Construct transfer(address,uint256) selector
            let freeMem := mload(0x40)
            mstore(freeMem, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMem, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff))
            mstore(add(freeMem, 36), value)

            let success := call(gas(), token, 0, freeMem, 68, 0x00, 32)
            let returnDataSize := returndatasize()

            // Success if call succeeded and either returned true or returned 0 bytes
            let callPassed := and(
                success,
                or(
                    iszero(returnDataSize),
                    and(gt(returnDataSize, 0), eq(mload(0x00), 1))
                )
            )

            if iszero(callPassed) {
                mstore(0x00, 0x90b8ec18) // TokenTransferFailed() selector
                revert(0x1c, 0x04)
            }
        }
    }

    /**
     * @dev Assembly SafeTransferFrom helper.
     */
    function _safeTransferFrom(address token, address from, address to, uint256 value) internal {
        assembly {
            let freeMem := mload(0x40)
            mstore(freeMem, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMem, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff))
            mstore(add(freeMem, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff))
            mstore(add(freeMem, 68), value)

            let success := call(gas(), token, 0, freeMem, 100, 0x00, 32)
            let returnDataSize := returndatasize()

            let callPassed := and(
                success,
                or(
                    iszero(returnDataSize),
                    and(gt(returnDataSize, 0), eq(mload(0x00), 1))
                )
            )

            if iszero(callPassed) {
                mstore(0x00, 0x90b8ec18) // TokenTransferFailed() selector
                revert(0x1c, 0x04)
            }
        }
    }
}
