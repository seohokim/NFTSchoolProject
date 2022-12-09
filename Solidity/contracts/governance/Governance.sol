// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../libs/DataTypes.sol";
import "../interfaces/IGovernance.sol";
import "../utils/OwnableCustom.sol";


import "@openzeppelin/contracts/access/Ownable.sol";

import "hardhat/console.sol";

contract Governance is IGovernance, OwnableCustom {
    address private governanceOwner;
    address private nftCore;

    mapping(address => uint256) banList;
    Reported[] reportedQueue;
    mapping(address => uint256) reportedCounter;

    bytes32 public constant BAN_ADMIN = keccak256("POLICE");

    modifier onlyPolice(address caller) {
        require(hasRole(BAN_ADMIN, caller), "YOU ARE NOT POLICE");
        _;
    }

    modifier onlyInternal(address caller) {
        require(hasRole(DEFAULT_ADMIN_ROLE, caller) || hasRole(ALLOW_ROLE, caller), "NOT ALLOWED");
        _;
    }

    constructor(address owner, address core) {
        governanceOwner = owner;
        nftCore = core;

        _initializeOwnership(governanceOwner);
    }

    function _initializeOwnership(address newOwner) private {
        console.log("ok");
        _setupRole(DEFAULT_ADMIN_ROLE, newOwner);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        console.log("ok2");
        _setupRole(DEFAULT_ADMIN_ROLE, address(this));          // Allowed from myself
        console.log("ok3");
        _setupRole(BAN_ADMIN, newOwner);
        console.log("ok4");

        // Contract allowing
        require(nftCore != address(0), "YOU HAVE TO SET CORE CONTRACT FIRST");
        console.log("ok5");
        console.log(address(this));
        console.log("ok6");
    }

    function ban(address user, uint256 period) external onlyPolice(msg.sender) returns (bool) {
        require(period > 0, "PERIOD must be greater than 0");
        banList[user] = block.timestamp + period;
        return true;
    }

    function unban(address user) external onlyPolice(msg.sender) returns (bool) {
        require(block.timestamp >= banList[user], "Can't unban yet");
        delete banList[user];

        return true;
    }

    function emergency(address user) external onlyAdmin(msg.sender) {
        delete banList[user];
    }

    function report(address from, address reported, bytes memory description) external payable {
        reportedQueue.push(Reported(
            from, reported, description
        ));
    }

    function out() external onlyInternal(msg.sender) returns (Reported memory) {
        Reported memory value = reportedQueue[reportedQueue.length - 1];
        reportedQueue.pop();
        return value;
    }

    function popReportingCounter(address user) external onlyInternal(msg.sender) returns(uint256) {
        uint256 poped = reportedCounter[user];
        if (poped == 0)
            return 0;
        reportedCounter[user] = reportedCounter[user] - 1;

        return poped;
    }

    function giveReward(address user) external onlyAdmin(msg.sender) {
        reportedCounter[user] = reportedCounter[user] + 1;
    }
}