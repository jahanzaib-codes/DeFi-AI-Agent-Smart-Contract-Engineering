# Module 07: Rust & WebAssembly Smart Contract Development for Arbitrum Stylus

## Why Rust on Arbitrum Stylus?
1. **Gas Cost Reduction**: Arbitrum Stylus runs WebAssembly (WASM), making heavy computational tasks (cryptography, mathematical modeling, neural network inference verification) **10x to 100x cheaper** in gas than EVM opcodes.
2. **Memory Safety**: Rust's ownership and borrow checker completely eliminate null pointer dereferences and memory boundary exploits at compile time.
3. **EVM Interoperability**: Stylus contracts live alongside standard Solidity contracts and can call or be called by Solidity contracts using standard ABI definitions.
