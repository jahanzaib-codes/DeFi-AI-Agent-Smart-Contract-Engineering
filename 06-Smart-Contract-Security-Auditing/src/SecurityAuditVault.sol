// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/**
 * @title SecurityAuditVault
 * @author Jahanzaib (@jahanzaib-codes)
 * @notice Case study demonstrating Read-Only Reentrancy and State Synchronization attacks,
 *         along with audited, production-grade mitigations.
 */
contract SecurityAuditVault {
    mapping(address => uint256) public userBalances;
    uint256 public totalShares;

    bool private _locked;

    error ReentrantCall();
    error TransferFailed();
    error InsufficientBalance();

    event Deposit(address indexed user, uint256 amount, uint256 sharesMinted);
    event Withdraw(address indexed user, uint256 sharesBurned, uint256 amountReturned);

    modifier nonReentrant() {
        if (_locked) revert ReentrantCall();
        _locked = true;
        _;
        _locked = false;
    }

    /**
     * @notice Audited Deposit implementation.
     * @dev Follows Checks-Effects-Interactions strictly to eliminate reentrancy attack vectors.
     */
    function deposit() external payable nonReentrant {
        require(msg.value > 0, "Zero deposit");

        uint256 sharesToMint;
        uint256 currentBalance = address(this).balance - msg.value;

        if (totalShares == 0 || currentBalance == 0) {
            sharesToMint = msg.value;
        } else {
            // share calculation: (amount * totalShares) / currentBalance
            sharesToMint = (msg.value * totalShares) / currentBalance;
        }

        // Effect
        userBalances[msg.sender] += sharesToMint;
        totalShares += sharesToMint;

        emit Deposit(msg.sender, msg.value, sharesToMint);
    }

    /**
     * @notice Audited Withdraw implementation.
     */
    function withdraw(uint256 shares) external nonReentrant {
        if (shares == 0 || userBalances[msg.sender] < shares) revert InsufficientBalance();

        uint256 amountToReturn = (shares * address(this).balance) / totalShares;

        // Effect updated BEFORE external transfer
        userBalances[msg.sender] -= shares;
        totalShares -= shares;

        // Interaction
        (bool success, ) = payable(msg.sender).call{value: amountToReturn}("");
        if (!success) revert TransferFailed();

        emit Withdraw(msg.sender, shares, amountToReturn);
    }

    /**
     * @notice Read-only reentrancy defense: Returns virtual price only when not in middle of execution.
     * @dev VULNERABILITY NOTE: Unprotected price views allow malicious contracts to borrow flash loans,
     *      enter pool, and query inflated share prices during reentrancy.
     */
    function getVirtualPrice() external view returns (uint256) {
        // Enforce lock check even in view method to prevent third-party protocols from reading transitional state!
        if (_locked) revert ReentrantCall();
        if (totalShares == 0) return 1e18;
        return (address(this).balance * 1e18) / totalShares;
    }
}
