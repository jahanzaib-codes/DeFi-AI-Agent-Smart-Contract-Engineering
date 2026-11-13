# Module 05: Layer-2 Dynamics: Base & Arbitrum Ecosystems

## Rollup Economics
- **L2 Gas Formula**:
  $$\text{Fee}_{\text{total}} = (\text{Gas}_{\text{L2}} \times \text{BaseFee}_{\text{L2}}) + (\text{Calldata}_{\text{L1}} \times \text{BlobFee}_{\text{L1}} \times \text{Scalar})$$
- Under **EIP-4844 (Proto-Danksharding)**, L1 blob gas drastically dropped calldata costs, but zero-byte packing (`0x00` costs 4 gas vs non-zero 16 gas) still yields substantial savings on Base and Arbitrum.
- **Bitmaps** allow storing 256 boolean flags in a single 32-byte slot, eliminating individual 20k-gas `SSTORE` allocations.
