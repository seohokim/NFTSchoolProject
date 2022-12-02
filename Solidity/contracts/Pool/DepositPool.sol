// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../libs/DataTypes.sol";
import "../interfaces/IDepositPool.sol";

contract DepositPool is IDepositPool {
    function addDeposit(address from, uint256 amount) override public payable {
        require(msg.value == amount, "[DepositPool] Lack of msg.value");

        totalBalance += msg.value;
        userDepositedBalance[from] += amount;
    }
    
    function removeDeposit(address from, uint256 amount) override public payable {
        require(userDepositedBalance[from] >= amount, "[Deposit] Lack of user deposited amount");
        
        totalBalance -= amount;
        userDepositedBalance[from] -= amount;
        payable(from).call{value: amount}("");
    }

    function getUserBalance(address from) override public view returns(uint256) {
        return userDepositedBalance[from];
    }
}