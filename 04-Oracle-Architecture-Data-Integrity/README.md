# Module 04: Oracle Systems & Price Manipulation Resistance

## Core Defense Mechanisms
1. **L2 Sequencer Outage Mitigation**: On Base and Arbitrum, if the centralized sequencer goes down and restarts, price updates lag while arbitrageurs front-run liquidations. Enforcing a **1-hour grace period** prevents unfair liquidations.
2. **Round Completeness & Staleness**: Verifying `answeredInRound >= roundId` and `block.timestamp - updatedAt <= heartbeatThreshold`.
3. **Negative Price Rejection**: Guaranteeing `answer > 0` to safeguard against catastrophic zero/negative feed failures (e.g. historical LUNA/USD collapse).
