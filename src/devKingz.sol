// SPDX-License-Identifier: MIT

//  /$$$$$$$                       /$$   /$$ /$$
// | $$__  $$                     | $$  /$$/|__/
// | $$  \ $$  /$$$$$$  /$$    /$$| $$ /$$/  /$$ /$$$$$$$   /$$$$$$  /$$$$$$$$
// | $$  | $$ /$$__  $$|  $$  /$$/| $$$$$/  | $$| $$__  $$ /$$__  $$|____ /$$/
// | $$  | $$| $$$$$$$$ \  $$/$$/ | $$  $$  | $$| $$  \ $$| $$  \ $$   /$$$$/
// | $$  | $$| $$_____/  \  $$$/  | $$\  $$ | $$| $$  | $$| $$  | $$  /$$__/
// | $$$$$$$/|  $$$$$$$   \  $/   | $$ \  $$| $$| $$  | $$|  $$$$$$$ /$$$$$$$$
// |_______/  \_______/    \_/    |__/  \__/|__/|__/  |__/ \____  $$|________/
//                                                         /$$  \ $$
//                                                        |  $$$$$$/
//                                                         \______/
//   _
//  | |__ _  _
//  | '_ \ || |
//  |_.__/\_, |
//        |__/
//    _____            __                __      __              .__                   .___
//   /  _  \ _________/  |_  ____   ____/  \    /  \_____ _______|  |   ___________  __| _/
//  /  /_\  \\___   /\   __\/ __ \_/ ___\   \/\/   /\__  \\_  __ \  |  /  _ \_  __ \/ __ |
// /    |    \/    /  |  | \  ___/\  \___\        /  / __ \|  | \/  |_(  <_> )  | \/ /_/ |
// \____|__  /_____ \ |__|  \___  >\___  >\__/\  /  (____  /__|  |____/\____/|__|  \____ |
//         \/      \/           \/     \/      \/        \/                             \/

pragma solidity ^0.8.19;

import {ERC721URIStorage, ERC721} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {VRFConsumerBaseV2Plus} from "@chainlink-brownie/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {
    IVRFCoordinatorV2PlusInternal
} from "@chainlink-brownie/contracts/src/v0.8/vrf/dev/interfaces/IVRFCoordinatorV2PlusInternal.sol";
import {VRFV2PlusClient} from "@chainlink-brownie/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title DevKingz
 * @author Michael Vargas
 * @notice A contract for minting DevKingz NFTs
 * @dev DevKingz NFTs are randomly minted using Chainlink VRF
 * @dev When we mint an NFT, we will trigger a Chainlink VRF request for a random number
 * @dev Using that random number, we will determine which DevKingz NFT to mint
 * @dev GoldDev, SilverDev, or LilDev
 * @dev GoldDev has a 5% chance of being minted "Super Rare"
 * @dev SilverDev has a 20% chance of being minted "Rare"
 * @dev LilDev has a 75% chance of being minted "Common"
 * @dev Users have to pay a mint fee to mint an NFT
 * @dev The owner of the contract can withdraw the mint fees
 */
contract DevKingz is ERC721URIStorage, VRFConsumerBaseV2Plus, ReentrancyGuard {
    /* Errors */
    error DevKingz__RangeOutOfBounds();
    error DevKingz__NeedMoreEthSent();
    error DevKingz__TransferFailed();
    error DevKingz__AlreadyInitialized();
    error DevKingz__NotWarlord();
    error DevKingz__NoFundsToWithdraw();
    error DevKingz__InvalidRequestId();
    error DevKingz__MaxSupplyReached();

    /* Types of DevKingz */
    enum Dev {
        GOLDDEV,
        SILVERDEV,
        LILDEV
    }

    /* Chainlink VRF Variables */
    IVRFCoordinatorV2PlusInternal private immutable I_VRF_COORDINATOR;
    bytes32 private immutable I_KEY_HASH; // keyHash
    uint256 private immutable I_SUB_ID;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private immutable I_CALLBACK_GAS_LIMIT;
    uint32 private constant NUM_WORDS = 1;

    /* NFT Variables */
    uint256 private immutable I_MINT_FEE;
    uint256 private s_tokenCounter = 0;
    uint256 internal constant MAX_CHANCE_VALUE = 400;
    uint256 public constant MAX_SUPPLY = 400;
    string[] internal s_devTokenUris;
    bool private s_initialized;

    /* OnlyOwner Variables */
    address private immutable I_OWNER;

    /* VRF Helpers */
    mapping(uint256 => address) private s_requestIdToSender;

    /* Events */
    event NFTRequested(uint256 indexed requestId, address indexed requester);
    event NFTMinted(uint256 indexed tokenId, Dev indexed devType, address indexed minter);
    event WithdrawFunds(address indexed owner, uint256 amount);

    constructor(
        address vrfCoordinatorV2,
        uint256 subId,
        bytes32 keyHash, // keyHash
        uint32 callbackGasLimit,
        uint256 mintFee,
        string[3] memory devTokenUris
    ) VRFConsumerBaseV2Plus(vrfCoordinatorV2) ERC721("DevKingz", "DKZ") {
        s_vrfCoordinator = IVRFCoordinatorV2PlusInternal(vrfCoordinatorV2);
        I_KEY_HASH = keyHash;
        I_SUB_ID = subId;
        I_MINT_FEE = mintFee;
        I_CALLBACK_GAS_LIMIT = callbackGasLimit;
        _initializeContract(devTokenUris);
        s_tokenCounter = 0;
        I_OWNER = msg.sender;
    }

    /*//////////////////////////////////////////////////////////////
                            MODIFIERS
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev Throws if called by any account other than the owner.
     */

    modifier onlyWarlord() {
        _onlyWarlord();
        _;
    }

    function _onlyWarlord() internal view {
        if (msg.sender != I_OWNER) revert DevKingz__NotWarlord();
    }

    /*//////////////////////////////////////////////////////////////
                            NFT MINTING LOGIC
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev Checks if minter has ETH in there wallet for mintFee.
     *      Calls a request for randomness from Chainlink VRF.
     *      Then emits an event
     */
    function requestNft() external payable returns (uint256 requestId) {
        if (msg.value < I_MINT_FEE) {
            revert DevKingz__NeedMoreEthSent();
        }

        uint256 excess = msg.value - I_MINT_FEE;

        if (s_tokenCounter >= MAX_SUPPLY) {
            revert DevKingz__MaxSupplyReached();
        }

        if (excess > 0) {
            (bool refunded,) = payable(msg.sender).call{value: excess}("");
            if (!refunded) revert DevKingz__TransferFailed();
        }

        requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: I_KEY_HASH,
                subId: I_SUB_ID,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: I_CALLBACK_GAS_LIMIT,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
            })
        );

        s_requestIdToSender[requestId] = msg.sender;
        emit NFTRequested(requestId, msg.sender);
    }

    /**
     * @dev This is the function that Chainlink VRF will call with the random words.
     *      We will use the random word to determine which DevKingz NFT to mint using custom logic in getDevFromModdedRng function.
     *      Then we will mint the NFT to the minter's address with the appropriate token URI.
     */
    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        address devOwner = s_requestIdToSender[requestId];
        if (devOwner == address(0)) {
            revert DevKingz__InvalidRequestId();
        }

        if (s_tokenCounter >= MAX_SUPPLY) {
            revert DevKingz__MaxSupplyReached();
        }

        uint256 newTokenId = s_tokenCounter;
        s_tokenCounter = s_tokenCounter + 1;
        uint256 moddedRng = (randomWords[0] % MAX_CHANCE_VALUE) + 1;
        Dev devType = getDevFromModdedRng(moddedRng);
        _safeMint(devOwner, newTokenId);
        _setTokenURI(newTokenId, s_devTokenUris[uint256(devType)]);
        emit NFTMinted(newTokenId, devType, devOwner);
    }

    /**
     * @dev This function determines which DevKingz NFT to mint based on the moddedRng value.
     *      It uses a cumulative probability approach where we check if the moddedRng falls within certain ranges.
     *      The ranges are determined by the chanceArray which is defined in getChanceArray function.
     *      @dev GoldDev has a 5% chance   (1–20   out of 400)
     *      @dev SilverDev has a 20% chance (21–100  out of 400)
     *      @dev LilDev has a 75% chance   (101–400 out of 400)
     */
    function getChanceArray() public pure returns (uint256[3] memory) {
        return [uint256(20), 100, MAX_CHANCE_VALUE];
    }

    function _initializeContract(string[3] memory devTokenUris) private {
        if (s_initialized) {
            revert DevKingz__AlreadyInitialized();
        }
        s_devTokenUris = devTokenUris;
        s_initialized = true;
    }

    /**
     * @dev This function takes in a moddedRng value and determines which DevKingz NFT to mint based on the ranges defined in the chanceArray.
     *      If the moddedRng is between 1 and 20, we mint a GoldDev (Super Rare).
     *      If the moddedRng is between 21 and 100, we mint a SilverDev (Rare).
     *      If the moddedRng is between 101 and 400, we mint a LilDev (Common).
     */
    function getDevFromModdedRng(uint256 moddedRng) public pure returns (Dev) {
        uint256 cummulativeSum = 1;
        uint256[3] memory chanceArray = getChanceArray();
        for (uint256 i = 0; i < chanceArray.length; i++) {
            if (moddedRng >= cummulativeSum && moddedRng <= chanceArray[i]) {
                return Dev(i);
            }
            cummulativeSum = chanceArray[i] + 1;
        }
        revert DevKingz__RangeOutOfBounds();
    }

    /*//////////////////////////////////////////////////////////////
                            WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev This function allows the owner of the contract to withdraw the funds from the contract.
     *      It checks if there are funds to withdraw, then transfers the funds to the owner. It also emits an event after the transfer.
     */
    function withdrawFunds() public onlyWarlord nonReentrant {
        uint256 amount = address(this).balance;
        if (amount == 0) {
            revert DevKingz__NoFundsToWithdraw();
        }
        // Robust transfer with error handling
        (bool success,) = payable(I_OWNER).call{value: amount}("");
        if (!success) {
            revert DevKingz__TransferFailed();
        }
        emit WithdrawFunds(I_OWNER, amount);
    }

    /*//////////////////////////////////////////////////////////////
                            GETTER FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev Getter functions for the contract variables. These are not strictly necessary, but they are useful for testing and for external users to interact with the contract.
     */
    function getMintFee() external view returns (uint256) {
        return I_MINT_FEE;
    }

    function getDevTokenUris(uint256 index) external view returns (string memory) {
        return s_devTokenUris[index];
    }

    function getTokenCounter() external view returns (uint256) {
        return s_tokenCounter;
    }

    function getRequestIdToSender(uint256 requestId) external view returns (address) {
        return s_requestIdToSender[requestId];
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
