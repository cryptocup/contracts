pragma solidity ^0.4.18;


contract DataSourceInterface {

    function isDataSource() public pure returns (bool);

    function getGroupResult(uint matchId) external;
    function getRoundOfSixteenTeams(uint index) external;
    function getRoundOfSixteenResult(uint matchId) external;
    function getQuarterResult(uint matchId) external;
    function getSemiResult(uint matchId) external;
    function getFinalTeams() external;
    function getYellowCards() external;
    function getRedCards() external;

}
