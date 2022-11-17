// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../libs/DataTypes.sol";

import "hardhat/console.sol";

contract PendingQueue {
    address private core;
    DataTypes.PendingMetadata[] public pendingQueue;
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
        require(pendingQueue.length > 0, "There is no pending element");
        pendingQueue[index] = pendingQueue[pendingQueue.length - 1];
        pendingQueue.pop();
    }

    function acceptRequest() external onlyNFT returns (uint256) {
        uint256 accepted = 0;
        uint256 currentTime = block.timestamp;

        // Based on Quick sort algorithm for gas efficiency
        _sortingByTime(pendingQueue, 0, int(pendingQueue.length - 1));
        for (uint256 i = 0; i < pendingQueue.length; i++) {
            DataTypes.PendingMetadata storage pending = pendingQueue[i];

            if (currentTime >= pending.requestedTime + PERIOD) {
                remove(i);
                accepted += 1;
            } else {
                break;
            }
        }
        // console.log(accepted);
        return accepted;
    }

    // private function
    function _sortingByTime(DataTypes.PendingMetadata[] storage arr, int left, int right) private {
        int i = left;
        int j = right;
        if (i == j) return;
        DataTypes.PendingMetadata storage pivot = arr[uint(left + (right - left) / 2)];

        while (i < j) {
            while (arr[uint(i)].requestedTime < pivot.requestedTime) i++;
            while (pivot.requestedTime < arr[uint(j)].requestedTime) j--;
            if (i <= j) {
                (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j)
            _sortingByTime(arr, left, j);
        if (i < right)
            _sortingByTime(arr, i, right);
    }
}