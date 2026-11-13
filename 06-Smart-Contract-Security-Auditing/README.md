# Module 06: Smart Contract Security, Attack Vectors & Invariant Auditing

## Attack Vectors Analyzed
1. **Read-Only Reentrancy**: Exploited when external DeFi protocols query a contract's view function (`getVirtualPrice`) while state is temporarily inconsistent during an ongoing transfer.
2. **Checks-Effects-Interactions Pattern**: State modifications must precede external calls to eliminate classic DAO reentrancy.
3. **Flash Loan Price Manipulation**: Defense against transient liquidity dilution via invariant assertion.
