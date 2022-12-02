// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../libs/DataTypes.sol";
import "../interfaces/IDepositPool.sol";

contract DepositPool is IDepositPool {
    address public owner;
    constructor() {
        owner = address(msg.sender);
    }

    function addNFTDeposit(address owner_, uint256 tokenID, uint256 deposited) override external payable {
        require(msg.value >= deposited, "Need more msg.value");
        require(userDepositedBalance[owner_][tokenID] == 0, "Already deposited this NFT");

        userDepositedBalance[owner_][tokenID] = deposited;
    }

    function deleteNFTDeposit(address owner_, uint256 tokenID) override external payable {
        require(userDepositedBalance[owner_][tokenID] != 0, "You does not have this NFT token");

        uint256 amount = userDepositedBalance[owner_][tokenID];
        
        delete userDepositedBalance[owner_][tokenID];
        payable(owner_).call{value: amount}("");
    }

    function addDeposit(uint256 amount) override public payable {
        require(msg.value == amount, "[DepositPool] Lack of msg.value");
        totalBalance += msg.value;
    }
    
    function removeDeposit(uint256 amount) override public payable {
        require(totalBalance >= amount, "[DepositPool] Lack of amount of balance");
        totalBalance -= amount;
        // Send to contract owner
        payable(owner).call{value: amount}("");
    }
}