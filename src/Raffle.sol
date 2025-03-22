// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Smart/Decentralized raffle contract
 * @author Ichimo De Leon
 * @notice The code inside here is for learning purposes and is a sample raffle
 * @dev This code implements Chainlink VRFv2.5
 */

/* Imports */
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/* Contracts */
contract SmartRaffle is VRFConsumerBaseV2Plus {
    /* Errors */
    error SmartRaffle__SendMoreToEnterRaffle();
    error SmartRaffle__TransferFailed();
    error SmartRaffle__WaitMoreToPickWinner();

    /* State Variables */
    /// @dev The duration of each lottery in seconds
    uint256 private immutable i_timeIntervalInSeconds;
    uint256 private immutable i_entranceFee;

    uint256 private immutable i_previousTimestamp; /// @dev Previous snapshot of time for logic later on
    bytes32 private immutable i_keyHash; /// @dev The maximum amt. of wei specified -> requests in wei

    uint256 private immutable i_subscriptionId; /// @dev The subscription ID for the consumer contracts
    uint32 private immutable i_callbackGasLimit;

    // Which data structures should we use to track data (like players)?
    address payable[] private s_players;

    uint32 private constant NUM_WORDS = 1;
    uint16 private constant REQUEST_CONFIRMATIONS = 3; /// @dev The # of block confirmations before the Chainlink node responds

    /* Events */
    event RaffleEntered(address indexed newPlayer);

    /* Functions */
    constructor(
        uint256 entranceFee,
        uint256 timeIntervalInSeconds,
        address vrfCoordinatorAddress,
        bytes32 gasLane /* keyhash */,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinatorAddress) {
        i_entranceFee = entranceFee;
        i_timeIntervalInSeconds = timeIntervalInSeconds;

        i_previousTimestamp = block.timestamp; // Sets the previous timestamp in the constructor
        i_keyHash = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
    }

    function enterRaffle() external payable {
        if (msg.value < i_entranceFee)
            revert SmartRaffle__SendMoreToEnterRaffle(); /// @dev Brings up a error when msg.value < minimum amt required

        /// @dev Adds new player and emits event
        s_players.push(payable(msg.sender));

        emit RaffleEntered(msg.sender);
    } /// @notice Enter raffle (buy a lottery ticket)

    /* Objectives:
        1. Get random number
        2. Use random number -> pick player
        3. Be automatically called
    */
    function pickWinner() external {
        /// @dev Example: 1000 - 950 = 50, where the interval in seconds was 100 (50 < 100), which fails
        if ((block.timestamp - i_previousTimestamp) < i_timeIntervalInSeconds) {
            revert SmartRaffle__WaitMoreToPickWinner();
        }

        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient
            .RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            });
        uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
    } /// @notice Pick the winner (winner gets money at the end of raffle)

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];

        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success) revert SmartRaffle__TransferFailed();
    }

    /**
     * View / Pure (Getter) functions
     */
    function getEntranceFee() external view returns (uint256 entranceFee) {
        return i_entranceFee;
    }
}
