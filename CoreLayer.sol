pragma solidity ^0.4.18;

import "./GameLogicLayer.sol";

/**
* @title CoreLayer
* @author CryptoCup Team (https://cryptocup.io/about)
* @notice Main contract
*/
contract CoreLayer is GameLogicLayer {
    
    function CoreLayer() public {
        adminAddress = msg.sender;
        deploymentTime = now;
    }

    /** 
    * @dev Only accept eth from the admin
    */
    function() external payable {
        require(msg.sender == adminAddress);

    }

    function isDataSourceCallback() public pure returns (bool){
        return true;
    }   

    /** 
    * @notice Builds ERC721 token with the predictions provided by the user.
    * @param groups1  - First half of the group matches scores encoded in a uint192.
    * @param groups2 -  Second half of the groups matches scores encoded in a uint192.
    * @param brackets - Bracket information encoded in a uint160.
    * @param extra -    Extra information (number of red cards and yellow cards) encoded in a uint32.
    * @dev An automatic timestamp is added for internal use.
    */
    function buildToken(uint192 groups1, uint192 groups2, uint160 brackets, uint32 extra) external payable isNotPaused {

        Token memory token = Token({
            groups1: groups1,
            groups2: groups2,
            brackets: brackets,
            timeStamp: uint64(now),
            extra: extra
        });

        require(msg.value >= _getTokenPrice());
        require(msg.sender != address(0));
        require(tokens.length < WCCTOKEN_CREATION_LIMIT);
        require(tokensOfOwnerMap[msg.sender].length < 100);
        require(now < WORLD_CUP_START); //World cup Start

        uint256 tokenId = tokens.push(token) - 1;
        require(tokenId == uint256(uint32(tokenId)));

        _setTokenOwner(msg.sender, tokenId);
        LogTokenBuilt(msg.sender, tokenId, token);

    }

    /** 
    * @param tokenId - ID of token to get.
    * @return Returns all the valuable information about a specific token.
    */
    function getToken(uint256 tokenId) external view returns (uint192 groups1, uint192 groups2, uint160 brackets, uint64 timeStamp, uint32 extra) {

        Token storage token = tokens[tokenId];

        groups1 = token.groups1;
        groups2 = token.groups2;
        brackets = token.brackets;
        timeStamp = token.timeStamp;
        extra = token.extra;

    }

    /**
    * @notice Called by the development team once the World Cup has ended (adminPool is set) 
    * @dev Allows dev team to retrieve adminPool
    */
    function adminWithdrawBalance() external onlyAdmin {

        adminAddress.transfer(adminPool);
        adminPool = 0;

    }

    /**
    * @notice Allows any user to retrieve their asigned prize. This would be the sum of the price of all the tokens
    * owned by the caller of this function.
    * @dev If the caller has no prize, the function will revert costing no gas to the caller.
    */
    function withdrawPrize() external checkState(pointsValidationState.Finished){
        uint256 prize = 0;
        uint256[] memory tokenList = tokensOfOwnerMap[msg.sender];
        
        for(uint256 i = 0;i < tokenList.length; i++){
            prize += tokenToPayoutMap[tokenList[i]];
            tokenToPayoutMap[tokenList[i]] = 0;
        }
        
        require(prize > 0);
        msg.sender.transfer((prizePool.mul(prize)).div(1000000));
      
    }

    
    /**
    * @notice Gets current token price 
    */
    function _getTokenPrice() internal view returns(uint256 tokenPrice){

        if ( now >= THIRD_PHASE){
            tokenPrice = (150 finney);
        } else if (now >= SECOND_PHASE) {
            tokenPrice = (110 finney);
        } else if (now >= FIRST_PHASE) {
            tokenPrice = (75 finney);
        } else {
            tokenPrice = STARTING_PRICE;
        }

        require(tokenPrice >= STARTING_PRICE && tokenPrice <= (200 finney));

    }

    /**
    * @dev Sets the data source contract address 
    * @param _address Address to be set
    */
    function setDataSourceAddress(address _address) external onlyAdmin {
        
        DataSourceInterface c = DataSourceInterface(_address);

        require(c.isDataSource());

        dataSource = c;
        dataSourceAddress = _address;
    }

    /**
    * @notice Testing function to corroborate group data from oraclize call
    * @param x Id of the match to get
    * @return uint8 Team 1 goals
    * @return uint8 Team 2 goals
    */
    function getGroupData(uint x) external view returns(uint8 a, uint8 b){
        a = groupsResults[x].teamOneGoals;
        b = groupsResults[x].teamTwoGoals;  
    }

    /**
    * @notice Testing function to corroborate round of sixteen data from oraclize call
    * @return An array with the ids of the round of sixteen teams
    */
    function getBracketData() external view returns(uint8[16] a){
        a = bracketsResults.roundOfSixteenTeamsIds;
    }

    /**
    * @notice Testing function to corroborate brackets data from oraclize call
    * @param x Team id
    * @return The place the team reached
    */
    function getBracketDataMiddleTeamIds(uint8 x) external view returns(teamState a){
        a = bracketsResults.middlePhaseTeamsIds[x];
    }

    /**
    * @notice Testing function to corroborate finals data from oraclize call
    * @return the 4 (four) final teams ids
    */
    function getBracketDataFinals() external view returns(uint8[4] a){
        a = bracketsResults.finalsTeamsIds;
    }

    /**
    * @notice Testing function to corroborate extra data from oraclize call
    * @return amount of yellow and red cards
    */
    function getExtrasData() external view returns(uint16 a, uint16 b){
        a = extraResults.yellowCards;
        b = extraResults.redCards;  
    }

    //EMERGENCY CALLS
    //If something goes wrong or fails, these functions will allow retribution for token holders 

    /**
    * @notice if there is an unresolvable problem, users can call to this function to get a refund.
    */
    function emergencyWithdraw() external hasFinalized{

        uint256 balance = STARTING_PRICE * tokensOfOwnerMap[msg.sender].length;

        delete tokensOfOwnerMap[msg.sender];
        msg.sender.transfer(balance);

    }

     /**
    * @notice Let the admin cash-out the entire contract balance 10 days after game has finished.
    */
    function finishedGameWithdraw() external onlyAdmin hasFinished{

        uint256 balance = address(this).balance;
        adminAddress.transfer(balance);

    }
    
    /**
    * @notice Let the admin cash-out the entire contract balance 10 days after game has finished.
    */
    function emergencyWithdrawAdmin() external hasFinalized onlyAdmin{

        require(finalizedTime != 0 &&  now >= finalizedTime + 10 days );
        msg.sender.transfer(address(this).balance);

    }
}
