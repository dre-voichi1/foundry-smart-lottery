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
    error SmartRaffle__WaitMoreBeforePickingWinner(
        uint256 contractBalance,
        uint256 numberOfPlayers,
        uint256 raffleState
    );

    error SmartRaffle__RaffleNotOpen();

    /* Type Declarations */
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    /* State Variables */
    RaffleState private s_raffleState;

    /// @dev The duration of each lottery in seconds
    uint256 private immutable i_interval;
    uint256 private immutable i_entranceFee;

    uint256 private s_lastTimestamp; /// @dev Previous snapshot of time for logic later on
    bytes32 private immutable i_keyHash; /// @dev The maximum amt. of wei specified -> requests in wei

    uint256 private immutable i_subscriptionId; /// @dev The subscription ID for the consumer contracts
    uint32 private immutable i_callbackGasLimit;

    // Which data structures should we use to track data (like players)?
    address payable[] private s_players;
    address private s_recentWinner;

    uint32 private constant NUM_WORDS = 1;
    uint16 private constant REQUEST_CONFIRMATIONS = 3; /// @dev The # of block confirmations before the Chainlink node responds

    /* Events */
    event RaffleEntered(address indexed newPlayer);
    event PickedWinner(address indexed recentWinner);

    /* Functions */
    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;

        s_lastTimestamp = block.timestamp; // Sets the previous timestamp in the constructor
        i_keyHash = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;

        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() external payable {
        if (s_raffleState != RaffleState.OPEN)
            revert SmartRaffle__RaffleNotOpen();

        if (msg.value < i_entranceFee)
            revert SmartRaffle__SendMoreToEnterRaffle(); /// @dev Brings up a error when msg.value < minimum amt required

        /// @dev Adds new player and emits event
        s_players.push(payable(msg.sender));

        emit RaffleEntered(msg.sender);
    } /// @notice Enter raffle (buy a lottery ticket)

    /* Objectives:
        1. Get random number - ✅
        2. Use random number -> pick winner - ✅
        3. Be automatically called - ✅
    */
    function performUpkeep() external {
        /* Checks */
        (bool upkeepNeeded, ) = checkUpkeep("");

        if (!upkeepNeeded) {
            revert SmartRaffle__WaitMoreBeforePickingWinner(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }

        /* Effects */
        /// @dev Renews the s_players array to a new one & changes raffle state -> CALCULATING
        s_raffleState = RaffleState.CALCULATING;
        s_players = new address payable[](0);

        s_lastTimestamp = block.timestamp;

        /* Interactions */
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
        s_vrfCoordinator.requestRandomWords(request);
    } /// @notice Pick the winner (winner gets money at the end of raffle)

    /**
     * @dev For each lottery run, it has to meet these conditions before picking a winner:
     * 1. The time interval has passed between raffle runs
     * 2. The lottery is open
     * 3. The contract has ETH (players should've funded it when entering the raffle)
     * 5. Enough players have entered the raffle beforehand
     * 6. Implicitly, your subscription for Chainlink services has LINK
     * @param - ignored
     * @return upkeepNeeded - True if the lottry should restart
     * @return - ignored
     */
    function checkUpkeep(
        bytes memory /* checkData */
    ) public view returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool timeHasPassed = ((block.timestamp - s_lastTimestamp) >=
            i_interval);
        bool raffleIsOpen = s_raffleState == RaffleState.OPEN;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;

        upkeepNeeded =
            timeHasPassed &&
            raffleIsOpen &&
            hasBalance &&
            hasPlayers;

        return (upkeepNeeded, "0x0");
    }

    function fulfillRandomWords(
        uint256 /* requestId */,
        uint256[] calldata randomWords
    ) internal override {
        // Checks (Check requirements first)

        // Effects (Internal contract state changes)
        uint256 indexOfWinner = randomWords[0] % s_players.length; /// @dev Generates random numbers & picks winner
        address payable recentWinner = s_players[indexOfWinner];

        s_recentWinner = address(recentWinner);
        s_raffleState = RaffleState.OPEN;

        emit PickedWinner(s_recentWinner);

        // Interactions (External contract state changes)
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success) revert SmartRaffle__TransferFailed();
    }

    /**
     * View / Pure (Getter) functions
     */
    function getEntranceFee() external view returns (uint256 entranceFee) {
        return i_entranceFee;
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }
}
