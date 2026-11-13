// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface IOracleRouter {
    function getValidatedPrice(address asset) external view returns (uint256);
}

/**
 * @title AIAgentGuardrailGate
 * @author Jahanzaib (@jahanzaib-codes)
 * @notice Multi-tier on-chain policy and security gate for autonomous AI agents.
 *         Enforces calldata function selector whitelisting, live oracle price corridor checks,
 *         and emergency circuit breakers.
 */
contract AIAgentGuardrailGate {
    address public immutable owner;
    IOracleRouter public oracleRouter;

    // Allowed function selectors (e.g., bytes4(keccak256("swap(uint256,uint256,address)")))
    mapping(bytes4 => bool) public authorizedSelectors;
    
    // Max allowable slippage against oracle price in basis points (e.g., 100 = 1.0%)
    uint256 public maxSlippageBps = 100;
    bool public isEmergencyCircuitBroken;

    error Unauthorized();
    error CircuitBreakerActive();
    error FunctionSelectorForbidden(bytes4 selector);
    error PriceDeviationExceeded(uint256 oraclePrice, uint256 proposedPrice);
    error InvalidCalldata();

    event SelectorWhitelisted(bytes4 indexed selector, bool status);
    event CircuitBreakerTripped(address indexed trigger);
    event CircuitBreakerReset(address indexed resetBy);
    event SlippageBpsUpdated(uint256 newBps);

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    modifier whenHealthy() {
        if (isEmergencyCircuitBroken) revert CircuitBreakerActive();
        _;
    }

    constructor(address _oracleRouter) {
        owner = msg.sender;
        oracleRouter = IOracleRouter(_oracleRouter);
    }

    function setAuthorizedSelector(bytes4 selector, bool status) external onlyOwner {
        authorizedSelectors[selector] = status;
        emit SelectorWhitelisted(selector, status);
    }

    function tripCircuitBreaker() external {
        // Any authorized sentinel or owner can trip circuit breaker immediately
        if (msg.sender != owner) revert Unauthorized();
        isEmergencyCircuitBroken = true;
        emit CircuitBreakerTripped(msg.sender);
    }

    function resetCircuitBreaker() external onlyOwner {
        isEmergencyCircuitBroken = false;
        emit CircuitBreakerReset(msg.sender);
    }

    /**
     * @notice Inspects and validates an autonomous AI agent's calldata payload prior to execution.
     * @dev Extracts 4-byte selector from calldata and cross-references with policy database.
     */
    function validateAgentPayload(
        bytes calldata payload,
        address assetIn,
        uint256 executionPrice
    ) external view whenHealthy returns (bool) {
        if (payload.length < 4) revert InvalidCalldata();

        // 1. Extract 4-byte function selector via slice
        bytes4 selector = bytes4(payload[:4]);
        if (!authorizedSelectors[selector]) {
            revert FunctionSelectorForbidden(selector);
        }

        // 2. Oracle Corridor Verification
        if (assetIn != address(0) && address(oracleRouter) != address(0)) {
            uint256 oraclePrice = oracleRouter.getValidatedPrice(assetIn);
            
            // Check if proposed execution price deviates beyond acceptable slippage corridor
            uint256 priceDiff = oraclePrice > executionPrice 
                ? oraclePrice - executionPrice 
                : executionPrice - oraclePrice;
                
            uint256 deviationBps = (priceDiff * 10000) / oraclePrice;
            if (deviationBps > maxSlippageBps) {
                revert PriceDeviationExceeded(oraclePrice, executionPrice);
            }
        }

        return true;
    }
}
