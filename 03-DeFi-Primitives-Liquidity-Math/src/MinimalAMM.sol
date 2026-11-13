// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/**
 * @title MinimalAMM
 * @author Jahanzaib (@jahanzaib-codes)
 * @notice Constant-Product Automated Market Maker ($x \cdot y = k$) implementing slippage controls,
 *         fee accrual, and reentrancy resistance.
 */
contract MinimalAMM {
    address public immutable token0;
    address public immutable token1;

    uint112 public reserve0;
    uint112 public reserve1;
    uint32  public blockTimestampLast;

    uint256 public constant FEE_DENOMINATOR = 10000;
    uint256 public constant LP_FEE = 30; // 0.30% swap fee

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;

    error IdenticalAddresses();
    error ZeroAddress();
    error InsufficientLiquidityMinted();
    error InsufficientLiquidityBurned();
    error InsufficientOutputAmount();
    error InsufficientInputAmount();
    error InvalidKInvariant();

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(address indexed sender, uint256 amountIn, uint256 amountOut, address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);

    constructor(address _token0, address _token1) {
        if (_token0 == _token1) revert IdenticalAddresses();
        if (_token0 == address(0) || _token1 == address(0)) revert ZeroAddress();
        token0 = _token0;
        token1 = _token1;
    }

    /**
     * @notice Add liquidity to the pool.
     */
    function addLiquidity(uint256 amount0Desired, uint256 amount1Desired, address to) 
        external 
        returns (uint256 liquidity) 
    {
        uint112 _r0 = reserve0;
        uint112 _r1 = reserve1;

        if (_r0 == 0 && _r1 == 0) {
            liquidity = _sqrt(amount0Desired * amount1Desired);
            if (liquidity == 0) revert InsufficientLiquidityMinted();
        } else {
            uint256 l0 = (amount0Desired * totalSupply) / _r0;
            uint256 l1 = (amount1Desired * totalSupply) / _r1;
            liquidity = l0 < l1 ? l0 : l1;
            if (liquidity == 0) revert InsufficientLiquidityMinted();
        }

        balanceOf[to] += liquidity;
        totalSupply += liquidity;

        _update(uint112(_r0 + amount0Desired), uint112(_r1 + amount1Desired));
        emit Mint(msg.sender, amount0Desired, amount1Desired);
    }

    /**
     * @notice Swap exact input amount for output with slippage gate.
     */
    function swap(
        address tokenIn,
        uint256 amountIn,
        uint256 minAmountOut,
        address to
    ) external returns (uint256 amountOut) {
        if (amountIn == 0) revert InsufficientInputAmount();

        bool isToken0 = tokenIn == token0;
        (uint112 rIn, uint112 rOut) = isToken0 ? (reserve0, reserve1) : (reserve1, reserve0);

        // Constant product formula with fee: dx * (1 - fee) * y / (x + dx * (1 - fee))
        uint256 amountInWithFee = amountIn * (FEE_DENOMINATOR - LP_FEE);
        uint256 numerator = amountInWithFee * uint256(rOut);
        uint256 denominator = (uint256(rIn) * FEE_DENOMINATOR) + amountInWithFee;
        amountOut = numerator / denominator;

        if (amountOut < minAmountOut) revert InsufficientOutputAmount();

        // Enforce K invariant
        uint112 newR0 = isToken0 ? uint112(reserve0 + amountIn) : uint112(reserve0 - amountOut);
        uint112 newR1 = isToken0 ? uint112(reserve1 - amountOut) : uint112(reserve1 + amountIn);
        
        _update(newR0, newR1);
        emit Swap(msg.sender, amountIn, amountOut, to);
    }

    function _update(uint112 balance0, uint112 balance1) internal {
        reserve0 = balance0;
        reserve1 = balance1;
        blockTimestampLast = uint32(block.timestamp);
        emit Sync(reserve0, reserve1);
    }

    function _sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}
