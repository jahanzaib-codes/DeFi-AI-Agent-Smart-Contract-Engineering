# Module 01: EVM Architecture & Modern Foundry Toolchain

## Core Objectives
1. **EVM Execution Contexts**: Understand `CALL`, `DELEGATECALL`, `STATICCALL`, and memory expansion costs ($O(N^2)$ quadratic scaling).
2. **Storage Layout & Slot Optimization**: Master 32-byte word alignment and packing to minimize expensive cold `SLOAD` (2,100 gas) and `SSTORE` (20,000 gas) operations.
3. **Foundry Testing Workflows**: Write deterministic property fuzz tests and trace gas bottlenecks via `forge test --gas-report`.

## Architecture & Storage Packing
```
Slot 0: [ operator: 20 bytes ][ lastExecutionTimestamp: 8 bytes ][ executionCounter: 4 bytes ] = 32 Bytes
Slot 1: [ cumulativeVolumeUSD: 32 bytes ]
Slot 2: [ maxSingleTradeLimit: 16 bytes ][ cooldownDuration: 8 bytes ][ isEmergencyPaused: 1 byte ][ 7 bytes free ]
```

## Foundry Commands
```bash
# Compile contracts with optimizer enabled
forge build

# Run property-based fuzz test suite
forge test -vvv --fuzz-runs 500

# Inspect storage layout of a contract
forge inspect EVMStorageLayout storage
```
