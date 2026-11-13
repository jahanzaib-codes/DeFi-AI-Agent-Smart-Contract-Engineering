# Module 08: Autonomous AI Agents On-Chain Execution (ERC-4337)

## Core Architectural Design
1. **Scoped Session Keys**: Off-chain AI agents (running on LLM backends or RL algorithms) hold ephemeral session keys without possessing protocol owner keys.
2. **Whitelisted Targets**: Agents are strictly restricted to calling whitelisted protocol contracts (e.g., Aerodrome on Base, Camelot on Arbitrum).
3. **Daily Velocity Limits**: Mathematical caps on daily balance movement reset every 24 hours (`block.timestamp / 86400`).
