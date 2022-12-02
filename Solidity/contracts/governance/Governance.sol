// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../libs/DataTypes.sol";
import "../interfaces/IGovernance.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

contract Governance is IGovernance, Ownable {
    address private governanceOwner;
    address private nftCore;

    mapping(address => uint256) banList;
    Reported[] reportedQueue;
    mapping(address => uint256) reportedCounter;

    constructor(address owner, address core) {
        governanceOwner = owner;
        nftCore = core;

        _initializeOwnership(governanceOwner);
    }

    function _initializeOwnership(address newOwner) private {
        _transferOwnership(newOwner);
    }

    function ban(address user, uint256 period) external returns (bool) {
        require(period > 0, "PERIOD must be greater than 0");
        banList[user] = block.timestamp + period;
        return true;
    }

    function unban(address user) external returns (bool) {
        require(block.timestamp >= banList[user], "Can't unban yet");
        delete banList[user];

        return true;
    }

    function emergency(address user) external onlyOwner {
        delete banList[user];
    }

    function report(address from, address reported, bytes memory description) external payable {
        uint256 BASE_FEE = 0.0001 ether;
        uint256 realFee = BASE_FEE + (0.000001 ether * reportedCounter[from]);

        require(msg.value >= realFee, "Your fee is too low");
        reportedQueue.push(Reported(
            from, reported, description
        ));
    }

    function out() external returns (Reported memory) {
        Reported memory value = reportedQueue[reportedQueue.length - 1];
        reportedQueue.pop();
        return value;
    }
}