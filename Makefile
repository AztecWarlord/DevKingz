-include .env

.PHONY: all test clean deploy fund help install snapshot format anvil mint cast

DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
DEFAULT_ANVIL_KEY4 := 0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a

help:
	@echo "Usage:"
	@echo "  make deploy [ARGS=...]\n    example: make deploy ARGS=\"--network sepolia\""
	@echo ""
	@echo "  make fund [ARGS=...]\n    example: make deploy ARGS=\"--network sepolia\""

all: clean remove install update build

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

install :; forge install cyfrin/foundry-devops@0.2.2 --no-commit && forge install smartcontractkit/chainlink-brownie-contracts@1.1.1 --no-commit && forge install foundry-rs/forge-std@v1.8.2 --no-commit && forge install transmissions11/solmate@v6 --no-commit

# Update Dependencies
update:; forge update

build:; forge build

test :; forge test 

snapshot :; forge snapshot

format :; forge fmt

anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

NETWORK_ARGS := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY) --broadcast
NETWORK_ARGS2 := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY2) --broadcast

deploy_base-sepolia:
	@forge script script/DeployDevKingz.s.sol:DeployDevKingz --rpc-url $(BASE_SEPOLIA_CHAIN_ID) --account my_key --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv

ifeq ($(findstring --network sepolia,$(ARGS)),--network sepolia)
	NETWORK_ARGS := --rpc-url $(BASE_SEPOLIA_CHAIN_ID) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
endif

deploy:
	@forge script script/DeployDevKingz.s.sol:DeployDevKingz $(NETWORK_ARGS)

createSubscription:
	@forge script script/Interactions.s.sol:CreateSubscription $(NETWORK_ARGS)

addConsumer:
	@forge script script/Interactions.s.sol:AddConsumer $(NETWORK_ARGS)

fundSubscription:
	@forge script script/Interactions.s.sol:FundSubscription $(NETWORK_ARGS)

mint:
	@forge script script/Interactions.s.sol:RequestNft $(NETWORK_ARGS)

castMint:
	@cast send 0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9 "requestNft()" --value 1ether   --private-key 0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a --rpc-url http://localhost:8545

	#cast call 0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9 "s_tokenCounter()" --rpc-url http://localhost:8545

	# to call fulfillRandomWords on live Anvil, you can use the following command:
	# cast send 0x5FbDB2315678afecb367f032d93F642f64180aa3 "fulfillRandomWords(uint256,address)" \ 1 \ 0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9 \ --private-key 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d \ --rpc-url http://localhost:8545

# For local testing, you can use the following command to deploy the contract to your local Anvil instance:
# forge script script/DeployDevKingz.s.sol:DeployDevKingz --rpc-url http://localhost:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast
