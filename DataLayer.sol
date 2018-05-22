pragma solidity ^0.4.18;

import "./DataSourceInterface.sol";

/**
* @title DataLayer.
* @author CryptoCup Team (https://cryptocup.io/about)
*/
contract DataLayer{

    
    uint256 constant WCCTOKEN_CREATION_LIMIT = 5000000;
    uint256 constant STARTING_PRICE = 45 finney;
    
    /// Epoch times based on when the prices change.
    uint256 constant FIRST_PHASE  = 1527476400;
    uint256 constant SECOND_PHASE = 1528081200;
    uint256 constant THIRD_PHASE  = 1528686000;
    uint256 constant WORLD_CUP_START = 1528945200;

    DataSourceInterface public dataSource;
    address public dataSourceAddress;

    address public adminAddress;
    uint256 public deploymentTime = 0;
    uint256 public gameFinishedTime = 0; //set this to now when oraclize was called.
    uint32 public lastCalculatedToken = 0;
    uint256 public pointsLimit = 0;
    uint32 public lastCheckedToken = 0;
    uint32 public winnerCounter = 0;
    uint32 public lastAssigned = 0;
    uint256 public auxWorstPoints = 500000000;
    uint32 public payoutRange = 0;
    uint32 public lastPrizeGiven = 0;
    uint256 public prizePool = 0;
    uint256 public adminPool = 0;
    uint256 public finalizedTime = 0;

    enum teamState { None, ROS, QUARTERS, SEMIS, FINAL }
    enum pointsValidationState { Unstarted, LimitSet, LimitCalculated, OrderChecked, TopWinnersAssigned, WinnersAssigned, Finished }
    
    /**
    * groups1     scores of the first half of matches (8 bits each)
    * groups2     scores of the second half of matches (8 bits each)
    * brackets    winner's team ids of each round (5 bits each)
    * timeStamp   creation timestamp
    * extra       number of yellow and red cards (16 bits each)
    */
    struct Token {
        uint192 groups1;
        uint192 groups2;
        uint160 brackets;
        uint64 timeStamp;
        uint32  extra;
    }

    struct GroupResult{
        uint8 teamOneGoals;
        uint8 teamTwoGoals;
    }

    struct BracketPhase{
        uint8[16] roundOfSixteenTeamsIds;
        mapping (uint8 => bool) teamExists;
        mapping (uint8 => teamState) middlePhaseTeamsIds;
        uint8[4] finalsTeamsIds;
    }

    struct Extras {
        uint16 yellowCards;
        uint16 redCards;
    }

    
    // List of all tokens
    Token[] tokens;

    GroupResult[48] groupsResults;
    BracketPhase bracketsResults;
    Extras extraResults;

    // List of all tokens that won 
    uint256[] sortedWinners;

    // List of the worst tokens (they also win)
    uint256[] worstTokens;
    pointsValidationState public pValidationState = pointsValidationState.Unstarted;

    mapping (address => uint256[]) public tokensOfOwnerMap;
    mapping (uint256 => address) public ownerOfTokenMap;
    mapping (uint256 => address) public tokensApprovedMap;
    mapping (uint256 => uint256) public tokenToPayoutMap;
    mapping (uint256 => uint16) public tokenToPointsMap;    


    event LogTokenBuilt(address creatorAddress, uint256 tokenId, Token token);
    event LogDataSourceCallbackList(uint8[] result);
    event LogDataSourceCallbackInt(uint8 result);
    event LogDataSourceCallbackTwoInt(uint8 result, uint8 result2);

}
