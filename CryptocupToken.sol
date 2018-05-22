pragma solidity ^0.4.18;

import "./ERC721.sol";
import "./AccessControlLayer.sol";

/**
* @title CryptoCupToken, main implemantations of the ERC721 standard
* @author CryptoCup Team (https://cryptocup.io/about)
*/
contract CryptocupToken is AccessControlLayer, ERC721 {

    //FUNCTIONALTIY
    /**
    * @notice checks if a user owns a token
    * @param userAddress - The address to check.
    * @param tokenId - ID of the token that needs to be verified.
    * @return true if the userAddress provided owns the token.
    */
    function _userOwnsToken(address userAddress, uint256 tokenId) internal view returns (bool){

         return ownerOfTokenMap[tokenId] == userAddress;

    }

    /**
    * @notice checks if the address provided is approved for a given token 
    * @param userAddress 
    * @param tokenId 
    * @return true if it is aproved
    */
    function _tokenIsApproved(address userAddress, uint256 tokenId) internal view returns (bool) {

        return tokensApprovedMap[tokenId] == userAddress;
    }

    /**
    * @notice transfers the token specified from sneder address to receiver address.
    * @param fromAddress the sender address that initially holds the token.
    * @param toAddress the receipient of the token.
    * @param tokenId ID of the token that will be sent.
    */
    function _transfer(address fromAddress, address toAddress, uint256 tokenId) internal {

      require(tokensOfOwnerMap[toAddress].length < 100);
      require(pValidationState == pointsValidationState.Unstarted);
      
      tokensOfOwnerMap[toAddress].push(tokenId);
      ownerOfTokenMap[tokenId] = toAddress;

      uint256[] storage tokenArray = tokensOfOwnerMap[fromAddress];
      for (uint256 i = 0; i < tokenArray.length; i++){
        if(tokenArray[i] == tokenId){
          tokenArray[i] = tokenArray[tokenArray.length-1];
        }
      }
      delete tokenArray[tokenArray.length-1];
      tokenArray.length--;

      delete tokensApprovedMap[tokenId];

    }

    /**
    * @notice Approve the address for a given token
    * @param tokenId - ID of token to be approved
    * @param userAddress - Address that will be approved
    */
    function _approve(uint256 tokenId, address userAddress) internal {
        tokensApprovedMap[tokenId] = userAddress;
    }

    /**
    * @notice set token owner to an address
    * @dev sets token owner on the contract data structures
    * @param ownerAddress address to be set
    * @param tokenId Id of token to be used
    */
    function _setTokenOwner(address ownerAddress, uint256 tokenId) internal{

    	tokensOfOwnerMap[ownerAddress].push(tokenId);
      ownerOfTokenMap[tokenId] = ownerAddress;
    
    }

    //ERC721 INTERFACE
    function name() public view returns (string){
      return "Cryptocup";
    }

    function symbol() public view returns (string){
      return "CC";
    }

    
    function balanceOf(address userAddress) public view returns (uint256 count) {
      return tokensOfOwnerMap[userAddress].length;

    }

    function transfer(address toAddress,uint256 tokenId) external isNotPaused {

      require(toAddress != address(0));
      require(toAddress != address(this));
      require(_userOwnsToken(msg.sender, tokenId));

      _transfer(msg.sender, toAddress, tokenId);
      LogTransfer(msg.sender, toAddress, tokenId);

    }


    function transferFrom(address fromAddress, address toAddress, uint256 tokenId) external isNotPaused {

      require(toAddress != address(0));
      require(toAddress != address(this));
      require(_tokenIsApproved(msg.sender, tokenId));
      require(_userOwnsToken(fromAddress, tokenId));

      _transfer(fromAddress, toAddress, tokenId);
      LogTransfer(fromAddress, toAddress, tokenId);

    }

    function approve( address toAddress, uint256 tokenId) external isNotPaused {

        require(toAddress != address(0));
        require(_userOwnsToken(msg.sender, tokenId));

        _approve(tokenId, toAddress);
        LogApproval(msg.sender, toAddress, tokenId);

    }

    function totalSupply() public view returns (uint) {

        return tokens.length;

    }

    function ownerOf(uint256 tokenId) external view returns (address ownerAddress) {

        ownerAddress = ownerOfTokenMap[tokenId];
        require(ownerAddress != address(0));

    }

    function tokensOfOwner(address ownerAddress) external view returns(uint256[] tokenIds) {

        tokenIds = tokensOfOwnerMap[ownerAddress];

    }

}
