# Module 03: Production DeFi Primitives & Liquidity Mathematics

## Mathematical Core
1. **Constant Product Invariant**:
   $$x \cdot y = k$$
2. **Swap Output Formulation (Including 30 bps LP Fee)**:
   $$\Delta y = \frac{y \cdot \Delta x \cdot (1 - \phi)}{x + \Delta x \cdot (1 - \phi)}$$
   Where $\phi = 0.003$ ($30\text{ bps}$).
3. **Liquidity Share Minting**:
   $$S = \min\left(\frac{\Delta x}{x} \cdot S_{\text{total}}, \frac{\Delta y}{y} \cdot S_{\text{total}}\right)$$
