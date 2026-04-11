# DevKingz

Randomized NFT minting project built with Foundry and Chainlink VRF v2.5.

## Status

- **Maturity:** Active development
- **Audit:** Not audited
- **Intended network:** Base Sepolia (`84532`) and local Anvil (`31337`)

Do not treat this repository as production-safe without a full security review, test hardening, and operational runbooks.

## What this project does

`DevKingz` is an ERC-721 collection that:

- requests verifiable randomness from Chainlink VRF,
- mints one of 3 NFT variants based on RNG,
- charges a mint fee,
- allows the owner ("Warlord") to withdraw contract funds.

Main contract: `src/devKingz.sol`

## Tech stack

- [Foundry](https://book.getfoundry.sh/) (`forge`, `cast`, `anvil`)
- [OpenZeppelin Contracts](https://github.com/OpenZeppelin/openzeppelin-contracts)
- [Chainlink Brownie Contracts](https://github.com/smartcontractkit/chainlink-brownie-contracts)
- [foundry-devops](https://github.com/Cyfrin/foundry-devops)

## Repository layout

```text
.
├── src/                      # Solidity contracts
├── script/                   # Deployment and interaction scripts
├── test/                     # Unit/integration tests
├── lib/                      # External dependencies
├── foundry.toml              # Foundry configuration
└── Makefile                  # Common local commands
```

## Prerequisites

- Linux/macOS shell
- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Git

Install Foundry tools:

```bash
foundryup
```

## Installation

```bash
git clone <repository-url>
cd DevKingz
forge install
forge build
```

## Environment variables

Create a `.env` file in the repository root. Minimum variables:

```dotenv
BASE_SEPOLIA_RPC_URL=
PRIVATE_KEY=
ETHERSCAN_API_KEY=
```

Optional/common:

```dotenv
RPC_URL=http://127.0.0.1:8545
```

Never commit real private keys or funded API keys.

## Local development

Start local chain:

```bash
make anvil
```

In another terminal:

```bash
forge build
forge test -vvv
forge fmt --check
forge snapshot
```

## Deployment

### Local Anvil

```bash
make deploy
```

or

```bash
forge script script/DeployDevKingz.s.sol:DeployDevKingz \
   --rpc-url http://localhost:8545 \
   --private-key <ANVIL_PRIVATE_KEY> \
   --broadcast -vvvv
```

### Base Sepolia

```bash
forge script script/DeployDevKingz.s.sol:DeployDevKingz \
   --rpc-url $BASE_SEPOLIA_RPC_URL \
   --private-key $PRIVATE_KEY \
   --broadcast --verify \
   --etherscan-api-key $ETHERSCAN_API_KEY -vvvv
```

## VRF subscription flow

Deployment script behavior (`script/DeployDevKingz.s.sol`):

1. Loads network config from `HelperConfig`.
2. If `subId == 0`, creates and funds a new subscription.
3. Deploys `DevKingz`.
4. Adds deployed contract as VRF consumer.

Manual scripts (if needed):

```bash
make createSubscription
make fundSubscription
make addConsumer
make mint
```

## Operations

Useful runtime actions:

- Request an NFT via contract `requestNft()` with mint fee.
- Withdraw accumulated mint fees via `withdrawFunds()` (owner only).
- Read state via getters (`getMintFee`, `getTokenCounter`, `getContractBalance`, etc.).

## Security notes

- This codebase is **not audited**.
- Treat all deployments as experimental until external review is complete.
- Recommended before mainnet:
   - Independent audit
   - Fuzz/invariant testing expansion
   - Full incident response runbook
   - Key management policy (hardware wallet / multisig)

## CI

GitHub Actions workflow in `.github/workflows/test.yml` runs:

- `forge fmt --check`
- `forge build --sizes`
- `forge test -vvv`

## Contributing

1. Create a feature/fix branch.
2. Keep changes scoped and tested.
3. Run local checks before opening PR:

```bash
forge fmt --check
forge build
forge test -vvv
```

## License

No root `LICENSE` file is currently present in this repository.
Add one before any public production release.

## Acknowledgments

- Foundry
- Chainlink
- OpenZeppelin
- Cyfrin/foundry-devops

[![Michael Vargas Linkedin](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/michael-vargas-a5b51b223/)
[![Michael Vargas Twitter](https://img.shields.io/badge/Twitter-1DA1F2?style=for-the-badge&logo=twitter&logoColor=white)](https://twitter.com/warlord_aztec)