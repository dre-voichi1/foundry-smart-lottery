// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {SmartRaffle} from "src/Raffle.sol";
import {Test} from "@forge-std/Test.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";

contract RaffleTest is Test {
    /* State Variables */
    HelperConfig public helperConfig;
    SmartRaffle public smartRaffle;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;

    /* State Variables - Raffle Parameters */
    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint256 subscriptionId;
    uint32 callbackGasLimit;

    /* Events */
    event RaffleEntered(address indexed newPlayer);

    function setUp() external {
        DeployRaffle deployRaffle = new DeployRaffle();
        (smartRaffle, helperConfig) = deployRaffle.deployContract();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        entranceFee = config.entranceFee;
        interval = config.interval;
        vrfCoordinator = config.vrfCoordinator;
        gasLane = config.gasLane;
        subscriptionId = config.subscriptionId;
        callbackGasLimit = config.callbackGasLimit;

        // Set up tests
        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
    }

    function testRaffleInitializesInOpenState() public view {
        assert(smartRaffle.getRaffleState() == SmartRaffle.RaffleState.OPEN);
    }

    /*//////////////////////////////////////////////////////////////
                              ENTER RAFFLE
    //////////////////////////////////////////////////////////////*/
    function testIfRaffleRevertsWhenYouDontPayEnough() public {
        // Arrange
        vm.prank(PLAYER);

        // Act / Assert
        vm.expectRevert(
            SmartRaffle.SmartRaffle__SendMoreToEnterRaffle.selector
        );
        smartRaffle.enterRaffle();
    }

    function testRaffleRecordsPlayersWhenTheyEnter() public {
        // Arrange
        vm.prank(PLAYER);

        // Act
        smartRaffle.enterRaffle{value: entranceFee}();

        // Assert
        address playerRecorded = smartRaffle.getPlayer(0);
        assertEq(playerRecorded, PLAYER);
    }

    function testRaffleEmitsEventWhenPlayerEntersRaffle() public {
        // Arrange
        vm.prank(PLAYER);

        // Act
        vm.expectEmit(true, false, false, false, address(smartRaffle));
        emit RaffleEntered(PLAYER);

        // Assert
        smartRaffle.enterRaffle{value: entranceFee}();
    }

    function testIfRaffleDoesntAllowPlayersWhileItIsStillCalculating() public {
        // Arrange
        vm.prank(PLAYER);
        smartRaffle.enterRaffle{value: entranceFee}();

        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        smartRaffle.performUpkeep("");

        // Act / Assert
        vm.expectRevert(SmartRaffle.SmartRaffle__RaffleNotOpen.selector);

        vm.prank(PLAYER);
        smartRaffle.enterRaffle{value: entranceFee}();
    }
}
