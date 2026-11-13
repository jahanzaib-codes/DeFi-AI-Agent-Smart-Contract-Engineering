# Flagship Project 1: AI Agent On-Chain Guardrail Vault

## Overview
**Target Chains**: Base (Aerodrome ecosystem), Arbitrum One (Camelot / Uniswap V3)  
**Primary Language**: Solidity (`^0.8.24`), Foundry  
**Standards**: ERC-4337 Account Abstraction, ERC-4626 Tokenized Vaults

## Architectural Blueprint
```
[ Off-Chain Autonomous Agent ] ──(UserOp via Session Key)──► [ EntryPoint (ERC-4337) ]
                                                                     │
                                                                     ▼
                                                          [ Guardrail Gate ]
                                                          ├─ Daily Velocity Cap
                                                          ├─ Method Selector Whitelist
                                                          └─ Oracle Slippage Gate
                                                                     │
                                                                     ▼
                                                          [ Execution Target: DEX ]
```

## Core Security Features
1. **Dynamic Session Keys**: Ephemeral signing keys with configurable expiration.
2. **Oracle Slippage Corridors**: Real-time cross-referencing with Chainlink price feeds.
3. **Emergency Circuit Breaker**: Instantaneous freeze upon anomalous transaction volume.
