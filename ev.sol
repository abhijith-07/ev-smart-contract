// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EvCharging {

    uint256 private chargingRate; // Initial rate set by the owner

    struct ChargingInfo {
        uint256 chargingDuration; // Time the user can charge
        uint256 chargingStartTime; // Time the startCharging function initiated
        uint256 chargingEndTime; // Time the Charging Ends
        address chargerOwner; // Owner of the charger
        uint256 paidAmount; // Amount the user pays while start charging
        uint256 chargerType; // Type of the charger : 1, 2, 3
        uint256 chargingUnit; // Unit of charge charged by the user, send by the charging station (IOT)
    }

    mapping(address => mapping(uint256 => ChargingInfo)) private chargingInfo;// multiple charging, chargerid to info

    address private chargingUser; // Address of the user who started the charging
    address public owner; // Owner of the contract

    modifier onlyChargingUser() {
        require(msg.sender == chargingUser, "Only the user who started charging can stop charging");
        _;
    }

    constructor(uint256 _chargingRate){
        owner = msg.sender;
        chargingRate = _chargingRate;
    }

    function getChargingRate() public view returns(uint256){
        return chargingRate;
    }

    function startCharging(address _chargerOwner, uint256 _chargerID, uint256 _chargerType) public payable {
        require( msg.value >= chargingRate, "You need to send an amount greater than minimum charging rate");
        
        ChargingInfo storage info = chargingInfo[msg.sender][_chargerID]; //Mapping the address of the evuser

        require( info.chargingStartTime == 0, "Charging already started");

        // Update the paidAmount with the amount sent
        info.paidAmount = msg.value;

        //Duration to charge by the amount given
        info.chargingDuration = msg.value / chargingRate;

        //User who iniate charging
        chargingUser = msg.sender;

        //Owner of the charger
        info.chargerOwner = _chargerOwner;

        // Charging Start time as the block iniated time
        info.chargingStartTime = block.timestamp;

        // Type of the charger
        info.chargerType = _chargerType;
        
        // Update the chargingInfo mapping
        chargingInfo[msg.sender][_chargerID] = info;
    }

    function stopCharging(uint256 _chargerID, uint256 _chargingUnit) external onlyChargingUser {
        ChargingInfo storage info = chargingInfo[msg.sender][_chargerID];

        info.chargingEndTime = block.timestamp; // End Time of charging

        // Calculating the charging time
        uint256 totalTime = info.chargingEndTime - info.chargingStartTime;

        // Calculating cost by time
        uint256 chargingCostTime = totalTime * chargingRate;

        // Calculating cost by time
        uint256 chargingCostIOT =  _chargingUnit * chargingRate;

        // Total charging cost
        uint256 chargingCost = chargingCostTime + chargingCostIOT;

        // Balance Return to the ev user
        uint256 balanceReturn = info.paidAmount - chargingCost;

        // Send the charging cost to the charger owner
        (bool chargerOwnerTransferSuccess, ) = payable(info.chargerOwner).call{value: chargingCost}("");
        require(chargerOwnerTransferSuccess, "Transfer to charger owner failed.");

        // Send the balance amount back to the EV user
        (bool userTransferSuccess, ) = payable(msg.sender).call{value: balanceReturn}("");
        require(userTransferSuccess, "Transfer to EV user failed.");

        // Reset the chargingStartTime
        info.chargingStartTime = 0;
    }

    //Calculate the amount needed to charge
    function chargingCalculate(uint256 _minutesTime, uint256 _chargerType, uint256 _chargingUnit) public view returns (uint256) {

        //Convert minutes to seconds
        uint256 secondsTime = _minutesTime * 60; 

        //Calculating cost by time and charger type
        uint256 costTime = secondsTime * _chargerType * chargingRate;

        //Calculating cost by charger current used unit
        uint256 costIOT = _chargingUnit * chargingRate;
        
        uint256 totalCost = costTime + costIOT;

        return totalCost;
    }
}
