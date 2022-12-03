// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../libs/DataTypes.sol";
import "../interfaces/IDepositPool.sol";
import "../utils/OwnableCustom.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";

contract DepositPool is IDepositPool, OwnableCustom {
    constructor(address core) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _initializeAllowedContract(core);
    }

    function _initializeAllowedContract(address core) private onlyAdmin(msg.sender) {
        addAllowedContract(address(core));
    }

    function addNFTDeposit(address owner_, uint256 tokenID, uint256 deposited) override external payable onlyAllowed(msg.sender) {
        require(msg.value >= deposited, "Need more msg.value");
        require(userDepositedBalance[owner_][tokenID] == 0, "Already deposited this NFT");

        userDepositedBalance[owner_][tokenID] = deposited;
    }

    function deleteNFTDeposit(address owner_, uint256 tokenID) override external payable onlyAllowed(msg.sender) {
        require(userDepositedBalance[owner_][tokenID] != 0, "You does not have this NFT token");

        uint256 amount = userDepositedBalance[owner_][tokenID];
        
        delete userDepositedBalance[owner_][tokenID];
        payable(owner_).call{value: amount}("");
    }

    function addDeposit(uint256 amount) override public payable onlyAdmin(msg.sender) {             // 지금은 onlyOwner인 이유는 일단 임시로 관리자만 사용 가능한 함수로 지정해두고, 이후에 사용 용도를 확실하게 만들 예정
        require(msg.value == amount, "[DepositPool] Lack of msg.value");
        totalBalance += msg.value;
    }
    
    function removeDeposit(uint256 amount) override public payable onlyAdmin(msg.sender) {
        require(totalBalance >= amount, "[DepositPool] Lack of amount of balance");
        totalBalance -= amount;
        // Send to contract owner
        payable(getOwner()).call{value: amount}("");
    }
}