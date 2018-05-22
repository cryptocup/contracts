pragma solidity ^0.4.18;

import "./CryptocupToken.sol";
import "./SafeMath.sol";

/**
* @title GameLogicLayer, contract in charge of everything related to calculating points, asigning
* winners, and distributing prizes.
* @author CryptoCup Team (https://cryptocup.io/about)
*/
contract GameLogicLayer is CryptocupToken{

    using SafeMath for *;

    uint8 TEAM_RESULT_MASK_GROUPS = 15;
    uint160 RESULT_MASK_BRACKETS = 31;
    uint16 EXTRA_MASK_BRACKETS = 65535;

    uint16 private lastPosition;
    uint16 private superiorQuota;
    
    uint16[] private payDistributionAmount = [1,1,1,1,1,1,1,1,1,1,5,5,10,20,50,100,100,200,500,1500,2500];
    uint32[] private payoutDistribution;

	event LogGroupDataArrived(uint matchId, uint8 result, uint8 result2);
    event LogRoundOfSixteenArrived(uint id, uint8 result);
    event LogMiddlePhaseArrived(uint matchId, uint8 result);
    event LogFinalsArrived(uint id, uint8[4] result);
    event LogExtrasArrived(uint id, uint16 result);
    
    //ORACLIZE
    function dataSourceGetGroupResult(uint matchId) external onlyAdmin{
        dataSource.getGroupResult(matchId);
    }

    function dataSourceGetRoundOfSixteen(uint index) external onlyAdmin{
        dataSource.getRoundOfSixteenTeams(index);
    }

    function dataSourceGetRoundOfSixteenResult(uint matchId) external onlyAdmin{
        dataSource.getRoundOfSixteenResult(matchId);
    }

    function dataSourceGetQuarterResult(uint matchId) external onlyAdmin{
        dataSource.getQuarterResult(matchId);
    }
    
    function dataSourceGetSemiResult(uint matchId) external onlyAdmin{
        dataSource.getSemiResult(matchId);
    }

    function dataSourceGetFinals() external onlyAdmin{
        dataSource.getFinalTeams();
    }

    function dataSourceGetYellowCards() external onlyAdmin{
        dataSource.getYellowCards();
    }

    function dataSourceGetRedCards() external onlyAdmin{
        dataSource.getRedCards();
    }

    /**
    * @notice sets a match result to the contract storage
    * @param matchId id of match to check
    * @param result number of goals the first team scored
    * @param result2 number of goals the second team scored
    */
    
    function dataSourceCallbackGroup(uint matchId, uint8 result, uint8 result2) public {

        require (msg.sender == dataSourceAddress);
        require (matchId >= 0 && matchId <= 47);

        groupsResults[matchId].teamOneGoals = result;
        groupsResults[matchId].teamTwoGoals = result2;

        LogGroupDataArrived(matchId, result, result2);

    }

    /**
    * @notice sets the sixteen teams that made it through groups to the contract storage
    * @param id index of sixteen teams
    * @param result results to be set
    */

    function dataSourceCallbackRoundOfSixteen(uint id, uint8 result) public {

        require (msg.sender == dataSourceAddress);

        bracketsResults.roundOfSixteenTeamsIds[id] = result;
        bracketsResults.teamExists[result] = true;
        
        LogRoundOfSixteenArrived(id, result);

    }

    function dataSourceCallbackTeamId(uint matchId, uint8 result) public {
        require (msg.sender == dataSourceAddress);

        teamState state = bracketsResults.middlePhaseTeamsIds[result];

        if (matchId >= 48 && matchId <= 55){
            if (state < teamState.ROS)
                bracketsResults.middlePhaseTeamsIds[result] = teamState.ROS;
        } else if (matchId >= 56 && matchId <= 59){
            if (state < teamState.QUARTERS)
                bracketsResults.middlePhaseTeamsIds[result] = teamState.QUARTERS;
        } else if (matchId == 60 || matchId == 61){
            if (state < teamState.SEMIS)
                bracketsResults.middlePhaseTeamsIds[result] = teamState.SEMIS;
        }

        LogMiddlePhaseArrived(matchId, result);
    }

    /**
    * @notice sets the champion, second, third and fourth teams to the contract storage
    * @param id 
    * @param result ids of the four teams
    */
    function dataSourceCallbackFinals(uint id, uint8[4] result) public {

        require (msg.sender == dataSourceAddress);

        uint256 i;

        for(i = 0; i < 4; i++){
            bracketsResults.finalsTeamsIds[i] = result[i];
        }

        LogFinalsArrived(id, result);

    }

    /**
    * @notice sets the number of cards to the contract storage
    * @param id 101 for yellow cards, 102 for red cards
    * @param result amount of cards
    */
    function dataSourceCallbackExtras(uint id, uint16 result) public {

        require (msg.sender == dataSourceAddress);

        if (id == 101){
            extraResults.yellowCards = result;
        } else if (id == 102){
            extraResults.redCards = result;
        }

        LogExtrasArrived(id, result);

    }

    /**
    * @notice check if prediction for a match winner is correct
    * @param realResultOne amount of goals team one scored
    * @param realResultTwo amount of goals team two scored
    * @param tokenResultOne amount of goals team one was predicted to score
    * @param tokenResultTwo amount of goals team two was predicted to score
    * @return 
    */
    function matchWinnerOk(uint8 realResultOne, uint8 realResultTwo, uint8 tokenResultOne, uint8 tokenResultTwo) internal pure returns(bool){

        int8 realR = int8(realResultOne - realResultTwo);
        int8 tokenR = int8(tokenResultOne - tokenResultTwo);

        return (realR > 0 && tokenR > 0) || (realR < 0 && tokenR < 0) || (realR == 0 && tokenR == 0);

    }

    /**
    * @notice get points from a single match 
    * @param matchIndex 
    * @param groupsPhase token predictions
    * @return 10 if predicted score correctly, 3 if predicted only who would win
    * and 0 if otherwise
    */
    function getMatchPointsGroups (uint256 matchIndex, uint192 groupsPhase) internal view returns(uint16 matchPoints) {

        uint8 tokenResultOne = uint8(groupsPhase & TEAM_RESULT_MASK_GROUPS);
        uint8 tokenResultTwo = uint8((groupsPhase >> 4) & TEAM_RESULT_MASK_GROUPS);

        uint8 teamOneGoals = groupsResults[matchIndex].teamOneGoals;
        uint8 teamTwoGoals = groupsResults[matchIndex].teamTwoGoals;

        if (teamOneGoals == tokenResultOne && teamTwoGoals == tokenResultTwo){
            matchPoints += 10;
        } else {
            if (matchWinnerOk(teamOneGoals, teamTwoGoals, tokenResultOne, tokenResultTwo)){
                matchPoints += 3;
            }
        }

    }

    /**
    * @notice calculates points from the last two matches
    * @param brackets token predictions
    * @return amount of points gained from the last two matches
    */
    function getFinalRoundPoints (uint160 brackets) internal view returns(uint16 finalRoundPoints) {

        uint8[3] memory teamsIds;

        for (uint i = 0; i <= 2; i++){
            brackets = brackets >> 5; //discard 4th place
            teamsIds[2-i] = uint8(brackets & RESULT_MASK_BRACKETS);
        }

        if (teamsIds[0] == bracketsResults.finalsTeamsIds[0]){
            finalRoundPoints += 100;
        }

        if (teamsIds[2] == bracketsResults.finalsTeamsIds[2]){
            finalRoundPoints += 25;
        }

        if (teamsIds[0] == bracketsResults.finalsTeamsIds[1]){
            finalRoundPoints += 50;
        }

        if (teamsIds[1] == bracketsResults.finalsTeamsIds[0] || teamsIds[1] == bracketsResults.finalsTeamsIds[1]){
            finalRoundPoints += 50;
        }

    }

    /**
    * @notice calculates points for round of sixteen, quarter-finals and semifinals
    * @param size amount of matches in round
    * @param round ros, qf, sf or f
    * @param brackets predictions
    * @return amount of points
    */
    function getMiddleRoundPoints(uint8 size, teamState round, uint160 brackets) internal view returns(uint16 middleRoundResults){

        uint8 teamId;

        for (uint i = 0; i < size; i++){
            teamId = uint8(brackets & RESULT_MASK_BRACKETS);

            if (uint(bracketsResults.middlePhaseTeamsIds[teamId]) >= uint(round) ) {
                middleRoundResults+=60;
            }

            brackets = brackets >> 5;
        }

    }

    /**
    * @notice calculates points for correct predictions of group winners
    * @param brackets token predictions
    * @return amount of points
    */
    function getQualifiersPoints(uint160 brackets) internal view returns(uint16 qualifiersPoints){

        uint8 teamId;

        for (uint256 i = 0; i <= 15; i++){
            teamId = uint8(brackets & RESULT_MASK_BRACKETS);

            if (teamId == bracketsResults.roundOfSixteenTeamsIds[15-i]){
                qualifiersPoints+=30;
            } else if (bracketsResults.teamExists[teamId]){
                qualifiersPoints+=25;
            }
            
            brackets = brackets >> 5;
        }

    }

    /**
    * @notice calculates points won by yellow and red cards predictions
    * @param extras token predictions
    * @return amount of points
    */
    function getExtraPoints(uint32 extras) internal view returns(uint16 extraPoints){

        uint16 redCards = uint16(extras & EXTRA_MASK_BRACKETS);
        extras = extras >> 16;
        uint16 yellowCards = uint16(extras);

        if (redCards == extraResults.redCards){
            extraPoints+=20;
        }

        if (yellowCards == extraResults.yellowCards){
            extraPoints+=20;
        }

    }

    /**
    * @notice calculates total amount of points for a token
    * @param t token to calculate points for
    * @return total amount of points
    */
    function calculateTokenPoints (Token memory t) internal view returns(uint16 points){
        
        //Groups phase 1
        uint192 g1 = t.groups1;
        for (uint256 i = 0; i <= 23; i++){
            points+=getMatchPointsGroups(23-i, g1);
            g1 = g1 >> 8;
        }

        //Groups phase 2
        uint192 g2 = t.groups2;
        for (i = 0; i <= 23; i++){
            points+=getMatchPointsGroups(47-i, g2);
            g2 = g2 >> 8;
        }
        
        uint160 bracketsLocal = t.brackets;

        //Brackets phase 1
        points+=getFinalRoundPoints(bracketsLocal);
        bracketsLocal = bracketsLocal >> 20;

        //Brackets phase 2 
        points+=getMiddleRoundPoints(4, teamState.QUARTERS, bracketsLocal);
        bracketsLocal = bracketsLocal >> 20;

        //Brackets phase 3 
        points+=getMiddleRoundPoints(8, teamState.ROS, bracketsLocal);
        bracketsLocal = bracketsLocal >> 40;

        //Brackets phase 4
        points+=getQualifiersPoints(bracketsLocal);

        //Extras
        points+=getExtraPoints(t.extra);

    }

    /**
    * @notice Sets the points of all the tokens between the last chunk set and the amount given.
    * @dev This function uses all the data collected earlier by oraclize to calculate points.
    * @param amount The amount of tokens that should be analyzed.
    */
	function calculatePointsBlock(uint32 amount) external{

        require (gameFinishedTime == 0);
        require(amount + lastCheckedToken <= tokens.length);


        for (uint256 i = lastCalculatedToken; i < (lastCalculatedToken + amount); i++) {
            uint16 points = calculateTokenPoints(tokens[i]);
            tokenToPointsMap[i] = points;
            if(worstTokens.length == 0 || points <= auxWorstPoints){
                if(worstTokens.length != 0 && points < auxWorstPoints){
                  worstTokens.length = 0;
                }
                if(worstTokens.length < 100){
                    auxWorstPoints = points;
                    worstTokens.push(i);
                }
            }
        }

        lastCalculatedToken += amount;
  	}

    /**
    * @notice Sets the structures for payout distribution, last position and superior quota. Payout distribution is the
    * percentage of the pot each position gets, last position is the percentage of the pot the last position gets,
    * and superior quota is the total amount OF winners that are given a prize.
    * @dev Each of this structures is dynamic and is assigned depending on the total amount of tokens in the game  
    */
    function setPayoutDistributionId () internal {
        if(tokens.length < 101){
            payoutDistribution = [289700, 189700, 120000, 92500, 75000, 62500, 52500, 42500, 40000, 35600, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
            lastPosition = 0;
            superiorQuota = 10;
        }else if(tokens.length < 201){
            payoutDistribution = [265500, 165500, 105500, 75500, 63000, 48000, 35500, 20500, 20000, 19500, 18500, 17800, 0, 0, 0, 0, 0, 0, 0, 0, 0];
            lastPosition = 0;
            superiorQuota = 20;
        }else if(tokens.length < 301){
            payoutDistribution = [260700, 155700, 100700, 70900, 60700, 45700, 35500, 20500, 17900, 12500, 11500, 11000, 10670, 0, 0, 0, 0, 0, 0, 0, 0];
            lastPosition = 0;
            superiorQuota = 30;
        }else if(tokens.length < 501){
            payoutDistribution = [238600, 138600, 88800, 63800, 53800, 43800, 33800, 18800, 17500, 12500, 9500, 7500, 7100, 6700, 0, 0, 0, 0, 0, 0, 0];
            lastPosition = 0;
            superiorQuota = 50;
        }else if(tokens.length < 1001){
            payoutDistribution = [218300, 122300, 72300, 52400, 43900, 33900, 23900, 16000, 13000, 10000, 9000, 7000, 5000, 4000, 3600, 0, 0, 0, 0, 0, 0];
            lastPosition = 4000;
            superiorQuota = 100;
        }else if(tokens.length < 2001){
            payoutDistribution = [204500, 114000, 64000, 44100, 35700, 26700, 22000, 15000, 11000, 9500, 8500, 6500, 4600, 2500, 2000, 1800, 0, 0, 0, 0, 0];
            lastPosition = 2500;
            superiorQuota = 200;
        }else if(tokens.length < 3001){
            payoutDistribution = [189200, 104800, 53900, 34900, 29300, 19300, 15300, 14000, 10500, 8300, 8000, 6000, 3800, 2500, 2000, 1500, 1100, 0, 0, 0, 0];
            lastPosition = 2500;
            superiorQuota = 300;
        }else if(tokens.length < 5001){
            payoutDistribution = [178000, 100500, 47400, 30400, 24700, 15500, 15000, 12000, 10200, 7800, 7400, 5500, 3300, 2000, 1500, 1200, 900, 670, 0, 0, 0];
            lastPosition = 2000;
            superiorQuota = 500;
        }else if(tokens.length < 10001){
            payoutDistribution = [157600, 86500, 39000, 23100, 18900, 15000, 14000, 11000, 9300, 6100, 6000, 5000, 3800, 1500, 1100, 900, 700, 500, 360, 0, 0];
            lastPosition = 1500;
            superiorQuota = 1000;
        }else if(tokens.length < 25001){
            payoutDistribution = [132500, 70200, 31300, 18500, 17500, 14000, 13500, 10500, 7500, 5500, 5000, 4000, 3000, 1000, 900, 700, 600, 400, 200, 152, 0];
            lastPosition = 1000;
            superiorQuota = 2500;
        } else {
            payoutDistribution = [120000, 63000,  27000, 18800, 17300, 13700, 13000, 10000, 6300, 5000, 4500, 3900, 2500, 900, 800, 600, 500, 350, 150, 100, 70];
            lastPosition = 900;
            superiorQuota = 5000;
        }

    }

    /**
    * @notice Sets the id of the last token that will be given a prize.
    * @dev This is done to offload some of the calculations needed for sorting, and to cap the number of sorts
    * needed to just the winners and not the whole array of tokens.
    * @param tokenId last token id
    */
    function setLimit(uint256 tokenId) external onlyAdmin{
        require(tokenId < tokens.length);
        require(pValidationState == pointsValidationState.Unstarted || pValidationState == pointsValidationState.LimitSet);
        pointsLimit = tokenId;
        pValidationState = pointsValidationState.LimitSet;
        lastCheckedToken = 0;
        lastCalculatedToken = 0;
        winnerCounter = 0;
        
        setPayoutDistributionId();
    }

    /**
    * @notice Sets the 10th percentile of the sorted array of points
    * @param amount tokens in a chunk
    */
    function calculateWinners(uint32 amount) external onlyAdmin checkState(pointsValidationState.LimitSet){
        require(amount + lastCheckedToken <= tokens.length);
        uint256 points = tokenToPointsMap[pointsLimit];

        for(uint256 i = lastCheckedToken; i < lastCheckedToken + amount; i++){
            if(tokenToPointsMap[i] > points ||
                (tokenToPointsMap[i] == points && i <= pointsLimit)){
                winnerCounter++;
            }
        }
        lastCheckedToken += amount;

        if(lastCheckedToken == tokens.length){
            require(superiorQuota == winnerCounter);
            pValidationState = pointsValidationState.LimitCalculated;
        }
    }

    /**
    * @notice Checks if the order given offchain coincides with the order of the actual previously calculated points
    * in the smart contract.
    * @dev the token sorting is done offchain so as to save on the huge amount of gas and complications that 
    * could occur from doing all the sorting onchain.
    * @param sortedChunk chunk sorted by points
    */
    function checkOrder(uint32[] sortedChunk) external onlyAdmin checkState(pointsValidationState.LimitCalculated){
        require(sortedChunk.length + sortedWinners.length <= winnerCounter);

        for(uint256 i=0;i < sortedChunk.length-1;i++){
            uint256 id = sortedChunk[i];
            uint256 sigId = sortedChunk[i+1];
            require(tokenToPointsMap[id] > tokenToPointsMap[sigId] ||
                (tokenToPointsMap[id] == tokenToPointsMap[sigId] &&  id < sigId));
        }

        if(sortedWinners.length != 0){
            uint256 id2 = sortedWinners[sortedWinners.length-1];
            uint256 sigId2 = sortedChunk[0];
            require(tokenToPointsMap[id2] > tokenToPointsMap[sigId2] ||
                (tokenToPointsMap[id2] == tokenToPointsMap[sigId2] && id2 < sigId2));
        }

        for(uint256 j=0;j < sortedChunk.length;j++){
            sortedWinners.push(sortedChunk[j]);
        }

        if(sortedWinners.length == winnerCounter){
            require(sortedWinners[sortedWinners.length-1] == pointsLimit);
            pValidationState = pointsValidationState.OrderChecked;
        }

    }

    /**
    * @notice If anything during the point calculation and sorting part should fail, this function can reset 
    * data structures to their initial position, so as to  
    */
    function resetWinners(uint256 newLength) external onlyAdmin checkState(pointsValidationState.LimitCalculated){
        
        sortedWinners.length = newLength;
    
    }

    /**
    * @notice Assigns prize percentage for the lucky top 30 winners. Each token will be assigned a uint256 inside
    * tokenToPayoutMap structure that represents the size of the pot that belongs to that token. If any tokens
    * tie inside of the first 30 tokens, the prize will be summed and divided equally. 
    */
    function setTopWinnerPrizes() external onlyAdmin checkState(pointsValidationState.OrderChecked){

        uint256 percent = 0;
        uint[] memory tokensEquals = new uint[](30);
        uint16 tokenEqualsCounter = 0;
        uint256 currentTokenId;
        uint256 currentTokenPoints;
        uint256 lastTokenPoints;
        uint32 counter = 0;
        uint256 maxRange = 13;
        if(tokens.length < 201){
          maxRange = 10;
        }
        

        while(payoutRange < maxRange){
          uint256 inRangecounter = payDistributionAmount[payoutRange];
          while(inRangecounter > 0){
            currentTokenId = sortedWinners[counter];
            currentTokenPoints = tokenToPointsMap[currentTokenId];

            inRangecounter--;

            //Special case for the last one
            if(inRangecounter == 0 && payoutRange == maxRange - 1){
                if(currentTokenPoints == lastTokenPoints){
                  percent += payoutDistribution[payoutRange];
                  tokensEquals[tokenEqualsCounter] = currentTokenId;
                  tokenEqualsCounter++;
                }else{
                  tokenToPayoutMap[currentTokenId] = payoutDistribution[payoutRange];
                }
            }

            if(counter != 0 && (currentTokenPoints != lastTokenPoints || (inRangecounter == 0 && payoutRange == maxRange - 1))){ //Fix second condition
                    for(uint256 i=0;i < tokenEqualsCounter;i++){
                        tokenToPayoutMap[tokensEquals[i]] = percent.div(tokenEqualsCounter);
                    }
                    percent = 0;
                    tokensEquals = new uint[](30);
                    tokenEqualsCounter = 0;
            }

            percent += payoutDistribution[payoutRange];
            tokensEquals[tokenEqualsCounter] = currentTokenId;
            
            tokenEqualsCounter++;
            counter++;

            lastTokenPoints = currentTokenPoints;
           }
           payoutRange++;
        }

        pValidationState = pointsValidationState.TopWinnersAssigned;
        lastPrizeGiven = counter;
    }

    /**
    * @notice Sets prize percentage to every address that wins from the position 30th onwards
    * @dev If there are less than 300 tokens playing, then this function will set nothing.
    * @param amount tokens in a chunk
    */
    function setWinnerPrizes(uint32 amount) external onlyAdmin checkState(pointsValidationState.TopWinnersAssigned){
        require(lastPrizeGiven + amount <= winnerCounter);
        
        uint16 inRangeCounter = payDistributionAmount[payoutRange];
        for(uint256 i = 0; i < amount; i++){
          if (inRangeCounter == 0){
            payoutRange++;
            inRangeCounter = payDistributionAmount[payoutRange];
          }

          uint256 tokenId = sortedWinners[i + lastPrizeGiven];

          tokenToPayoutMap[tokenId] = payoutDistribution[payoutRange];

          inRangeCounter--;
        }
        //i + amount prize was not given yet, so amount -1
        lastPrizeGiven += amount;
        payDistributionAmount[payoutRange] = inRangeCounter;

        if(lastPrizeGiven == winnerCounter){
            pValidationState = pointsValidationState.WinnersAssigned;
            return;
        }
    }

    /**
    * @notice Sets prizes for last tokens and sets prize pool amount
    */
    function setLastPositions() external onlyAdmin checkState(pointsValidationState.WinnersAssigned){
        
            
        for(uint256 j = 0;j < worstTokens.length;j++){
            uint256 tokenId = worstTokens[j];
            tokenToPayoutMap[tokenId] += lastPosition.div(worstTokens.length);
        }

        uint256 balance = address(this).balance;
        adminPool = balance.mul(25).div(100);
        prizePool = balance.mul(75).div(100);

        pValidationState = pointsValidationState.Finished;
        gameFinishedTime = now;
    }

}
