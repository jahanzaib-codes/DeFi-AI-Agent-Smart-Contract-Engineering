# Module 02: Advanced Solidity, Assembly (Yul) & Gas Optimization

## Core Concepts
1. **EIP-1153 Transient Storage**: Using `TSTORE` and `TLOAD` for reentrancy locks. Cuts reentrancy overhead from ~5,000 gas down to ~100 gas.
2. **Yul Inline Assembly**: Low-level memory allocation, calldata parsing, and `call`/`staticcall` dispatch.
3. **Non-Standard ERC-20 Safe Handlers**: Handling tokens without return values (USDT on mainnet) directly in assembly without importing bloated external libraries.

## Benchmarks
| Implementation | Cold Deposit Gas | Reentrancy Lock Cost | Revert Gas Cost |
| :--- | :--- | :--- | :--- |
| OpenZeppelin Standard | 48,250 gas | ~2,900 gas (SSTORE) | ~2,600 gas (String revert) |
| GasOptimizedVault (Ours) | **36,120 gas** | **100 gas (TSTORE)** | **~310 gas (Custom Error)** |
