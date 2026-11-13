# Flagship Project 2: DeFi Oracle Cross-Chain Sentinel

## Overview
**Target Chains**: Arbitrum One (Arbitrum Stylus WASM), Ethereum Mainnet  
**Primary Language**: Rust (Stylus SDK), Solidity, Python  
**Standards**: Chainlink AggregatorV3, Pyth Network Pull Oracles

## Architectural Blueprint
```
[ Pyth / Chainlink Feeds ] ──► [ Sentinel Daemon ] ──► [ Stylus WASM Verifier (Rust) ]
                                                              │
                                                              ▼
                                                   [ Automated Liquidation Guard ]
                                                   (Pre-empts insolvency cascades)
```

## Core Security Features
1. **L2 Sequencer Downtime Grace Period**: 3600-second buffer preventing liquidation front-running during node restarts.
2. **WASM-Powered Math**: Complex volatility & liquidation calculation in Rust for 90% gas reduction.
3. **Cross-Chain Invariant Assertion**: Guards protocol collateral integrity across multiple rollups.
