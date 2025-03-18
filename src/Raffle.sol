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

contract SmartRaffle {
    // Errors
    error SmartRaffle__SendMoreToEnterRaffle(uint256 amountSent);

    uint256 private immutable i_entranceFee;

    constructor(uint256 entranceFee) {
        i_entranceFee = entranceFee;
    }

    function enterRaffle() external payable {
        if (msg.value < i_entranceFee)
            revert SmartRaffle__SendMoreToEnterRaffle(msg.value);
    } // Enter raffle (buy a lottery ticket)

    function pickWinner() public {} // Pick the winner (winner gets money at the end of raffle)

    /**
     * View / Pure (Getter) functions
     */
    function getEntranceFee() external view returns (uint256 entranceFee) {
        return i_entranceFee;
    }
}
