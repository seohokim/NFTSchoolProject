// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../libs/DataTypes.sol";

contract PendingQueue {
    address private core;
    DataTypes.PendingMetadata[] pendingQueue;
    uint256 public constant PERIOD = 7 days;

    modifier onlyNFT() {
        require(msg.sender == core, "Not From Core Contract");
        _;
    }

    constructor() {
        core = address(msg.sender);
    }

    function isPending(uint256 token_id) public view returns (bool) {
        for (uint256 i = 0; i < pendingQueue.length; i++) {
            if (pendingQueue[i].id == token_id)
                return true;
        }
        return false;
    }

    function _findPendingMetadata(uint256 tokenId) private view returns (uint256) {
        for (uint256 i = 0; i < pendingQueue.length; i++) {
            if (pendingQueue[i].id == tokenId) {
                return i;
            }
        }
        return type(uint256).max;
    }

    function findPendingMetadata(uint256 tokenId) public view returns (uint256) {
        return _findPendingMetadata(tokenId);
    }

    function push(DataTypes.PendingMetadata memory data) public {
        pendingQueue.push(data);
    }

    function remove(uint256 index) public {
        pendingQueue[index] = pendingQueue[pendingQueue.length - 1];
        pendingQueue.pop();
    }

    function acceptRequest() external onlyNFT returns (uint256) {
        uint256 accepted = 0;
        uint256 currentTime = block.timestamp;

        for (uint256 i = pendingQueue.length - 1; i >= 0; i--) {
            DataTypes.PendingMetadata storage pending = pendingQueue[i];

            if (currentTime >= pending.requestedTime + PERIOD) {
                pendingQueue[i] = pendingQueue[pendingQueue.length - 1];

                pendingQueue.pop();
                accepted += 1;
            }
        }
        return accepted;
    }
}