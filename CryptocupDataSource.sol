pragma solidity ^0.4.18;

import "./oraclizeAPI.sol";
import "./stringUtils.sol";
import "./DataSourceCallbackInterface.sol";

/**
* @title CryptoCup Data Source:
* @author CryptoCup Team (https://cryptocup.io/about)
*/
contract CryptocupDataSource is usingOraclize{

	DataSourceCallbackInterface public callbackContract;
	address public callbackContractAddress;
    address public adminAddress;
    mapping (string => uint8) countryToIndexMap;


    event LogOraclizeQuery(string description);
    event LogOraclizeQuerySuccess(string result);

    struct oraclizeCallback {
        oraclizeState oState;
        uint id;
        bool valid;
    }
	
	enum oraclizeState { Groups, RoundOfSixteen, MiddleResult, Finals, Extras }
    mapping (bytes32 => oraclizeCallback) private oraclizeCallbacks;


	function CryptocupDataSource() public {
        adminAddress = msg.sender;
        _initializeCountriesMap();
    }

    function() payable{
        require (msg.sender == adminAddress);
        
    }

    /**
    * @notice initializes the map of countries 
    */
    function _initializeCountriesMap() internal {

        string[32] memory countries = ["Russia", "Egypt", "Morocco", "Nigeria", "Senegal", "Tunisia", "Australia", "Iran", "Japan", "Korea Republic", "Saudi Arabia", "Belgium", "Croatia", "Denmark", "England", "France", "Germany", "Iceland", "Poland", "Portugal", "Serbia", "Spain", "Sweden", "Switzerland", "Uruguay", "Costa Rica", "Mexico", "Panama", "Argentina", "Brazil", "Colombia", "Peru"];

        for(uint8 i = 0; i < countries.length; i++){
            countryToIndexMap[countries[i]] = i;
        }
            
    } 

    function isDataSource() public pure returns (bool){
    	return true;
    }

    /**
    * @notice Sets callback contract address
    * @param _address address to be set
    */
    function setCallbackAddress(address _address) external {
        
        require (msg.sender == adminAddress);

        DataSourceCallbackInterface c = DataSourceCallbackInterface(_address);

        require(c.isDataSourceCallback());

        callbackContract = c;
        callbackContractAddress = _address;
    }

    modifier onlyMainContract() { 
    	require (msg.sender == callbackContractAddress); 
    	_; 
    }
    

	using stringUtils for *;
    
    /**
    * @notice Get match result from calling the oraclize query
    * @param matchId the match id to get the result 
    */
	function getGroupResult(uint matchId) external onlyMainContract{

        string memory postValue = strConcat('{"matchId" :', uint2str(matchId), '}');

        if (oraclize_getPrice("URL") > this.balance) {
            LogOraclizeQuery("No ether for query.");
        } else {
            LogOraclizeQuery("Oraclize query sent.");
            bytes32 queryId = oraclize_query("URL", "BMWJkfgGdJY0y6IytqybT6C2SxE/Nmk/xA20a1thBLZWio6zi0jLaf7AA86JUx1tU6/S5JrD9VFm/2s57r0uXtvDZ3f7jA55eCfjebiMayeVsZr+RgnbsH3+DV3OkY6KA90N8E2SLnkUSdntHfwImnZWob/1srjIh2m64beLN49hk4QihFvR0a5RSDtqdswJM1Ec4ATbfYdvuqcRUf6SFo+M4fNZK5BrcgVX010gM+2Cy8VaD2l64ccRxTIW64h6ojirwa7Fks+o7TrUKo6qcQ==", postValue);
        }

        oraclizeCallbacks[queryId] = oraclizeCallback(oraclizeState.Groups, matchId, true);

    }

    /**
    * @notice gets the round of sixteen teams based on an index
    * @param index 0 to 15 
    */
    function getRoundOfSixteenTeams(uint index) external onlyMainContract{

        string memory postValue = strConcat('{"index" :', uint2str(index), '}');

        if (oraclize_getPrice("URL") > this.balance) {
            LogOraclizeQuery("No ether for query.");
        } else {
            LogOraclizeQuery("Oraclize query sent.");
            bytes32 queryId = oraclize_query("URL", "BMSji9K8ijlicFD03AiZbliyiEd/v53hl3AZ5AxNed+pntuAy8YtD+UAL4Q/RrmlBurbXPWRwxJkXW9NV+8CTo5YGakKOTLXHmAmT76zt+BsYzaPVNMOva9no/7/jHt1NfTewlw1ISF4X8gh7968YSeCXuCsz41TzUwgKxIWhbbStZqvY3p8mC/T6icKWdvE8Y5ajY5xk7SGAJYITW5nzxlJWZNHeYY3CFi6tECNtwkphNUt9I02hlC95BHoqU8ldubJXTZ8uQ8E4EK/Utnk", postValue);
        }

        oraclizeCallbacks[queryId] = oraclizeCallback(oraclizeState.RoundOfSixteen, index, true);

    }

    /**
    * @notice gets the winner of the round of sixteen matches 
    * @param matchId match to get the winner from
    */
    function getRoundOfSixteenResult(uint matchId) external onlyMainContract{

        string memory postValue = strConcat('{"matchId" :', uint2str(matchId), '}');

        if (oraclize_getPrice("URL") > this.balance) {
            LogOraclizeQuery("No ether for query.");
        } else {
            LogOraclizeQuery("Oraclize query sent.");
            
            bytes32 queryId = oraclize_query("URL", "BJjspRDbJ/CthOGB9OWRKQj319FduZMz7M6zIPWJ9JpEIV/iD1RoIqRtwYPV4VPt/ThUljDwoz/MuhejJ/oaAPMGIP2ypeKTJjs0MdSdQrUwRc7fQgD7E8hdergloI4QKQsL8lFkF29+HmvDs5BNq8XttjfaCH5GtPYRQGGmSvqQhbqzMUI9bDtptCMLBptgNIfFshQYWObYPBVFhxsapuOA/u7D3FYgx/fFbysoUMOrrLYyxI5As4J4R0M16AqugOuLsyUC2pwmFeQJdgYfSP30srSC",postValue);
        }

        oraclizeCallbacks[queryId] = oraclizeCallback(oraclizeState.MiddleResult, matchId, true);

    }

    /**
    * @notice gets the winner of the quarter-final matches 
    * @param matchId match to get the winner from
    */
    function getQuarterResult(uint matchId) external onlyMainContract{

        string memory postValue = strConcat('{"matchId" :', uint2str(matchId), '}');

        if (oraclize_getPrice("URL") > this.balance) {
            LogOraclizeQuery("No ether for query.");
        } else {
            LogOraclizeQuery("Oraclize query sent.");
            bytes32 queryId = oraclize_query("URL", "BCBE6GaskD7wWYaw+J25pVK3wiDyLUk3UPFYTGuQWHBhWfSmN4VpNQBhg9/Qg9fy0JdV0ZC4ZIA4R+8xBYF1QwFRGhe9rhOJb/SCzYCyDTB7XN+8qp5rXwDDY0FkxlUMhPcqbJzaj2oxM1kx9uPRPMgrXHYz7B5fKEnKDDi4xHAmPTGtZiwgx5nA9s4c93XZ8kduSrwHRxKrfsz4//USj3vZaZ873rkpUznRd0XTwd2hisZ22yt8p8cG+TTD5w83dc67CtN2u0Tj30sQHA==",postValue);
        }

        oraclizeCallbacks[queryId] = oraclizeCallback(oraclizeState.MiddleResult, matchId, true);

    }

    /**
    * @notice gets the winner of the semi-final matches 
    * @param matchId match to get the winner from
    */
    function getSemiResult(uint matchId) external onlyMainContract{

        string memory postValue = strConcat('{"matchId" :', uint2str(matchId), '}');

        if (oraclize_getPrice("URL") > this.balance) {
            LogOraclizeQuery("No ether for query.");
        } else {
            LogOraclizeQuery("Oraclize query sent.");
            bytes32 queryId = oraclize_query("URL", "BPBCN57jV537SdS6Wm7YAIaQkrmqZlxY3wAqBSGtahSm0PGb+pRvdzO46Xqq3L6kk0RBPdoa82nuyzflqjUREGArcuBxxqXldb0W/mwV8C01NdIGMbM2UnWRLgLLOoVtPrwgCZjAzJfaD5Bj3jsm8yMKiSgW41zdp/QT5Z87uEDrfKUbLeoB9LHFI8wg6mW+Yc5fvrikTz3TmIEzMZ1Si+s2f4k8S+dy2UNGzBbXj7/v4lqjqu5On4quzJPiiEOlxe7mrRC+AwnUlA==",postValue);
        }

        oraclizeCallbacks[queryId] = oraclizeCallback(oraclizeState.MiddleResult, matchId, true);

    }

    /**
    * @notice gets the champion, runner-up, third and fourth teams 
    */
    function getFinalTeams() external onlyMainContract{


        if (oraclize_getPrice("URL") > this.balance) {
            LogOraclizeQuery("No ether for query.");
        } else {
            LogOraclizeQuery("Oraclize query sent.");
            bytes32 queryId = oraclize_query("URL", "BCFmNm5tPI6bddsNXpDSLAHN97VGQNGMEYxPVQCmKz1+Iap7mIlwN1G7djk1eOEaWZcvWg5hvFB2dRIFcArrGm+pmaF/BL5sLwlnzPlEtvOziMZCl50P3UBsPFu/VcBUUlIFYmUXynYEOTizN1V0TzWgUYFJrDXd2lHeOS2rfaBI0h3JSqtLbqzRmIATn6XpM7CxchP4rItg9n9qYk13T7LOsDxNE+KQL0m+z/FC1L9MZdXxWpOgI+PGyX/aHCWdlsd6r7YnBWlJ7yknznBo");
        }

        oraclizeCallbacks[queryId] = oraclizeCallback(oraclizeState.Finals, 100, true);

    }

    /**
    * @notice gets the amount of yellow cards 
    */
    function getYellowCards() external onlyMainContract{


        if (oraclize_getPrice("URL") > this.balance) {
            LogOraclizeQuery("No ether for query.");
        } else {
            LogOraclizeQuery("Oraclize query sent.");
            bytes32 queryId = oraclize_query("URL", "BLlp0H5J6PweF0kdY39Lqm8uDynqJXcevMPVIK6cPIS4LN8jkIxerYgATIQlUj2/LltZiRje+LSONVg8m3kUz3/VCVFK8yJaZN9RTRuvcNEOhNj9lbwS28LBiMqr3FkUvk6EpfIOSzCvwPwCqhGHHufWH5wMYHTGqChqzdyb8ZuH/+3nI+rriNn8r/8yF92B6Cv0j+Ua1qpKGzNon4+GU8e2OR+/r+oqG+AsgOtopXMYeAU8ju2GUm9buYTvnQMYwMBxNdv+boBxbOU=");
        }

        oraclizeCallbacks[queryId] = oraclizeCallback(oraclizeState.Extras, 101, true);

    }

    /**
    * @notice gets the amount of red cards  
    */
    function getRedCards() external onlyMainContract{


        if (oraclize_getPrice("URL") > this.balance) {
            LogOraclizeQuery("No ether for query.");
        } else {
            LogOraclizeQuery("Oraclize query sent.");
            bytes32 queryId = oraclize_query("URL", "BGADuMlhWMYqDWoDuujLrDHPrU+fMVPRvgUcg6+rwOvNynP56qG12EDDr+1KcL/GH0bEo3oiJ2DSnHWMo3h19FEbvd65DmVj6+RnNiJEyzNgoTU03ryLLdCYxT5pzCZbD26CW5VNk/FpYr9e34IxLM+Kyqbqdina+uNTa8ObeD3xbqgGjWIutXA9j/7EP+gTRcxIMggtLAJlWPcT0BTXEjhQ9mf8DCHW8bpRJm2wUGoIvlQyjySuwS5GLvg3HeBqNYntfMTGbo8=");
        }

        oraclizeCallbacks[queryId] = oraclizeCallback(oraclizeState.Extras, 102, true);

    }

    function __callback(bytes32 myid, string result) public{

        require(msg.sender == oraclize_cbAddress());
        require(oraclizeCallbacks[myid].valid);

        oraclizeCallback memory o = oraclizeCallbacks[myid];

        uint256 i;

        if (o.oState == oraclizeState.Groups) {

            var teamTwoGoals = result.toSlice();
            var teamOneGoals = teamTwoGoals.split("-".toSlice());

            callbackContract.dataSourceCallbackGroup(o.id, uint8(parseInt(teamOneGoals.toString())), 
                uint8(parseInt(teamTwoGoals.toString())));
 			
        } else if (o.oState == oraclizeState.RoundOfSixteen){

            callbackContract.dataSourceCallbackRoundOfSixteen(o.id, countryToIndexMap[result]);
		
        } else if (o.oState == oraclizeState.MiddleResult) {

        	callbackContract.dataSourceCallbackTeamId(o.id, countryToIndexMap[result]);

        
        } else if (o.oState == oraclizeState.Finals){
        	
        	uint8[4] memory res2;

            var finalTeam = result.toSlice();
            for( i = 0; i < 4; i++){
                var c2 = finalTeam.split(",".toSlice());
                res2[i] = countryToIndexMap[c2.toString()];
            }

            callbackContract.dataSourceCallbackFinals(o.id, res2);

        } else if (o.oState == oraclizeState.Extras) {

        	callbackContract.dataSourceCallbackExtras(o.id, uint16(parseInt(result)));
        } 

        o.valid = false;
        LogOraclizeQuerySuccess(result);

    }

}
