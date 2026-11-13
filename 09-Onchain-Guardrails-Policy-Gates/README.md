# Module 09: On-Chain Guardrails & Policy Gates for Autonomous AI Agents

## Defense-in-Depth Specification
1. **Calldata Function Selector Inspection**: Extracts `bytes4(payload[:4])` to block agents from invoking privileged methods (`setOwner`, `upgradeTo`, `emergencyWithdraw`).
2. **Oracle Slippage Corridors**: Compares execution prices against live Chainlink/Pyth oracle benchmark prices to prevent sandwich attacks, MEV extraction, or rogue agent orders.
3. **Emergency Circuit Breaker**: Instantaneous freeze of all autonomous agent execution routes during market anomalies or model drift.
