pragma solidity ^0.4.18;


import "./DataLayer.sol";

/**
* @title AccessControlLayer
* @author CryptoCup Team (https://cryptocup.io/about)
* @dev Containes basic admin modifiers to restrict access to some functions. Allows
* for pauseing, and setting emergency stops.
*/
contract AccessControlLayer is DataLayer{

    bool public paused = false;
    bool public finalized = false;
    bool public saleOpen = true;

   /**
   * @dev Main modifier to limit access to delicate functions.
   */
    modifier onlyAdmin() {
        require(msg.sender == adminAddress);
        _;
    }

    /**
    * @dev Modifier that checks that the contract is not paused
    */
    modifier isNotPaused() {
        require(!paused);
        _;
    }

    /**
    * @dev Modifier that checks that the contract is paused
    */
    modifier isPaused() {
        require(paused);
        _;
    }

    /**
    * @dev Modifier that checks that the contract has finished successfully
    */
    modifier hasFinished() {
        require((gameFinishedTime != 0) && now >= (gameFinishedTime + (15 days)));
        _;
    }

    /**
    * @dev Modifier that checks that the contract has finalized
    */
    modifier hasFinalized() {
        require(finalized);
        _;
    }

    /**
    * @dev Checks if pValidationState is in the provided stats
    * @param state State required to run
    */
    modifier checkState(pointsValidationState state){
        require(pValidationState == state);
        _;
    }

    /**
    * @dev Transfer contract's ownership
    * @param _newAdmin Address to be set
    */
    function setAdmin(address _newAdmin) external onlyAdmin {

        require(_newAdmin != address(0));
        adminAddress = _newAdmin;
    }

    /**
    * @dev Sets the contract pause state
    * @param state True to pause
    */
    function setPauseState(bool state) external onlyAdmin {
        paused = state;
    }

    /**
    * @dev Sets the contract to finalized
    * @param state True to finalize
    */
    function setFinalized(bool state) external onlyAdmin {
        paused = state;
        finalized = state;
        if(finalized == true)
            finalizedTime = now;
    }
}