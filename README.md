# DevKingz

**DevKingz is a project built using Foundry, a blazing fast, portable, and modular toolkit for Ethereum application development written in Rust. That leverages the power of the ChainlinkVRF to generate provable RNG when minting a DevKingz NFT.**

## Overview

This project leverages Foundry's powerful tools to streamline Ethereum smart contract development and testing. It includes:

- **Forge**: A robust Ethereum testing framework.
- **Cast**: A versatile tool for interacting with EVM smart contracts, sending transactions, and retrieving chain data.
- **Anvil**: A local Ethereum node for development and testing.
- **Chisel**: A fast and verbose Solidity REPL.

## Project Structure

The project is organized as follows:

```
.
├── lib/                     # External libraries (e.g., Chainlink, OpenZeppelin)
├── script/                  # Deployment and interaction scripts
├── src/                     # Main Solidity contracts
├── test/                    # Unit and integration tests
├── cache/                   # Cached files for faster builds
├── foundry.toml             # Foundry configuration file
├── README.md                # Project documentation
```

## Documentation

For detailed documentation on Foundry, visit the [Foundry Book](https://book.getfoundry.sh/).

## Getting Started

### Prerequisites

Ensure you have the following installed:

- [Foundry](https://github.com/foundry-rs/foundry)
- Node.js (for managing dependencies in `lib/` if required)

### Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd DevKingz
   ```

2. Install dependencies:
   ```bash
   forge install
   ```

3. Build the project:
   ```bash
   forge build
   ```

## Usage

### Build

Compile the smart contracts:
```bash
forge build
```

### Test

Run the test suite:
```bash
forge test
```

### Format

Format your Solidity code:
```bash
forge fmt
```

### Gas Snapshots

Generate gas usage snapshots:
```bash
forge snapshot
```

### Anvil

Start a local Ethereum node:
```bash
anvil
```

### Deploy

Deploy contracts using a script:
```bash
forge script script/DeployDevKingz.s.sol:DeployScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

Interact with contracts using Cast:
```bash
cast <subcommand>
```

### Help

Get help for Foundry commands:
```bash
forge --help
anvil --help
cast --help
```

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository.
2. Create a new branch for your feature or bugfix.
3. Submit a pull request with a detailed description of your changes.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Foundry](https://github.com/foundry-rs/foundry) for providing the development toolkit.
- [Chainlink](https://chain.link/) and [OpenZeppelin](https://openzeppelin.com/) for their libraries.

---
Happy coding!

[![Michael Vargas Linkedin](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/michael-vargas-a5b51b223/)
[![Michael Vargas Twitter](https://img.shields.io/badge/Twitter-1DA1F2?style=for-the-badge&logo=twitter&logoColor=white)](https://twitter.com/warlord_aztec)