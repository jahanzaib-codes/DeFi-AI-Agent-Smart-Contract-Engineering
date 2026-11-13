# Module 10: Multi-Chain Deployment, Verification & Enterprise CI/CD

## Deployment & Verification Runbook
```bash
# Deploy to Base Sepolia with auto-verification on Basescan
forge script script/Deploy.s.sol:DeployScript \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --broadcast \
  --verify \
  --etherscan-api-key $BASESCAN_API_KEY

# Deploy to Arbitrum Sepolia with Arbiscan verification
forge script script/Deploy.s.sol:DeployScript \
  --rpc-url $ARBITRUM_SEPOLIA_RPC_URL \
  --broadcast \
  --verify \
  --etherscan-api-key $ARBISCAN_API_KEY
```
