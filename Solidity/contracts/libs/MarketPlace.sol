// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../libs/DataTypes.sol";

import "../utils/Util.sol";

contract MarketPlace {
    address private NFTCore;
    uint256 public constant AUCTION_PERIOD = 7 days;

    function initializeMarketPlace() external {
        NFTCore = msg.sender;
        require(Util.isContract(NFTCore), "NFTCore must be contract");
    }

    // MarketPlace need two implementation
    // 1. Auction
    // 2. Selling
    function makeMarket() external returns (uint256 marketID) {}
    function removeMarket(uint256 marketID) external returns (bool) {}
    function registerAuction() external returns (bool) {}
    function startAuction() external returns (bool) {}
    function endAuction() external returns (bool) {}

    // * Auction - Detail
    // 1. Auction needs marketplaces for each kind
    // 2. Auction should always open until the period is ended.
    // 3. Auction need to gather participants for starting auction



    // * Selling - Detail
    // 1. Each user can sell their NFT to other users directly.
    // 2. Selling does not need Marketplace
    function sell(address from, address to, uint256 token) external returns (uint256) {

    }

    // Getter & Setter
}