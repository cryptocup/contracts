pragma solidity ^0.4.18;

/**
* @title Linker contract between oraclize parser contract and the main contract
* @notice Functions that set the world cup results to the main contract storage
* @author Cryptocup Team (https://cryptocup.io/about)
*/
contract DataSourceCallbackInterface {

    /**
    * @notice checks if a contract has this interface implemented
    * @return true if it has, false if it has not
    */
    function isDataSourceCallback() public pure returns (bool);

    /**
    * @notice sets a match result to the contract storage
    * @param matchId id of match to check
    * @param teamOneGoals number of goals the first team scored
    * @param teamTwoGoals number of goals the second team scored
    */
    function dataSourceCallbackGroup(uint matchId, uint8 teamOneGoals, uint8 teamTwoGoals) public;
    
    
    /**
    * @notice sets the sixteen teams that made it through groups to the contract storage
    * @param id index 
    * @param result team id 
    */
    function dataSourceCallbackRoundOfSixteen(uint id, uint8 result) public;
    
    /**
    * @notice sets the champion, second, third and fourth teams to the contract storage
    * @param id 0
    * @param teamIds ids of the four teams
    */
    function dataSourceCallbackFinals(uint id, uint8[4] teamIds) public;
    
    /**
    * @notice sets who got to the next round
    * @param matchId id of the match
    * @param teamId id of the team
    */
    function dataSourceCallbackTeamId(uint matchId, uint8 teamId) public;    

    /**
    * @notice sets the number of cards to the contract storage
    * @param id yellow card or red card
    * @param extra amount of yellow and red cards
    */
    function dataSourceCallbackExtras(uint id, uint16 extra) public;    


}
