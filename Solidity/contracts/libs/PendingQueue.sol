// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../libs/DataTypes.sol";

import "hardhat/console.sol";

contract PendingQueue {
    address private core;
    DataTypes.PendingMetadata[] public pendingQueue;
    uint256 public constant PERIOD = 7 days;
    uint256 internal lastSortedBlock = 0;

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

    function acceptRequest() external onlyNFT returns (DataTypes.PendingMetadata memory) {
        uint256 currentTime = block.timestamp;

        DataTypes.PendingMetadata memory pending;

        // block.number를 이용해서 최종적으로 sorting된 시점을 구하고
        // 만약 최초로 acceptRequest가 실행이 된 것이라면 새로 _sortingByTime을 계산함
        // Based on Quick sort algorithm for gas efficiency
        if (lastSortedBlock != block.number) {
            _sortingByTime(pendingQueue, 0, int(pendingQueue.length - 1));
            lastSortedBlock = block.number;
        }
        // 기존에 있었던 코드는 전체를 순회하면서 처리하도록 구현되었음
        // 하지만 이번에는 큐가 비어있지 않을 경우 가장 위에 있는 큐를 하나씩 꺼내오도록 구현 변경
        /*
        for (uint256 i = 0; i < pendingQueue.length; i++) {
            DataTypes.PendingMetadata storage pending = pendingQueue[i];

            if (currentTime >= pending.requestedTime + PERIOD) {
                remove(i);
                accepted += 1;
            } else {
                break;
            }
        }
        */
        if (pendingQueue.length != 0) {
            // 만약 1개 이상의 Pending Queue가 존재하는 경우
            pending = pendingQueue[0];            // 가장 앞의 요소를 한 개 추출함
            if (currentTime >= pending.requestedTime + PERIOD) {
                // 대기 기간이 넘어갔을 경우
                remove(0);          // 0번째 요소를 삭제함
            }
            else {
                pending = DataTypes.PendingMetadata(0, address(0), DataTypes.MetaData(0), 0);
            }
        }
        else {
            pending = DataTypes.PendingMetadata(0, address(0), DataTypes.MetaData(0), 0);
        }
        // console.log(accepted);
        return pending;
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