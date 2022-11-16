// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../libs/DataTypes.sol";

import "../utils/Util.sol";

contract MarketPlace {
    address private NFTCore;
    address private owner;
    uint256 public constant AUCTION_PERIOD = 7 days;

    struct TokenItemInfo {
        bool isForAuction;
        address lastOwner;
        address lastParticipant;    // last changed auction participant address
        uint256 deadline;           // If this is for auction
        uint256 cost;
    }

    struct MarketInfo {
        uint256 marketID;
        bool isOpened;
        mapping(uint256 => TokenItemInfo) tokenList;
    }

    mapping(address => uint256) userDepositedBalances;
    mapping(uint256 => bool) marketExists;
    mapping(uint256 => MarketInfo) market;

    event InitializeMarketPlace(address owner, address core);

    event ApplyItem(address owner, uint256 tokenID, uint256 cost);
    event AlreadyApply(address owner, uint256 tokenID);
    event DeleteItem(address owner, uint256 tokenID);
    event ChangeItemCost(uint256 tokenID, uint256 newCost);

    event MarketCreated(uint256 marketID);

    modifier onlyCore {
        require(NFTCore == msg.sender, "Only allowed for NFT Core");
        _;
    }

    modifier onlyOwner {
        require(owner == msg.sender, "You are not owner");
        _;
    }

    modifier isMarketOpen(uint256 marketID) {
        require(marketExists[marketID] && market[marketID].isOpened, "Market is not opened!");
        _;
    }

    function initializeMarketPlace(address _owner) external {
        owner = _owner;
        NFTCore = msg.sender;
        require(Util.isContract(NFTCore), "NFTCore must be contract");

        emit InitializeMarketPlace(owner, NFTCore);
    }

    // MarketPlace need two implementation
    // 1. Auction
    // 2. Selling
    function makeMarket(uint256 marketID) external onlyOwner {
        require(!marketExists[marketID], "Market already exists");
        marketExists[marketID] = true;
        
        MarketInfo storage marketInfo = market[marketID];
        marketInfo.isOpened = false;
        marketInfo.marketID = marketID;

        emit MarketCreated(marketID);
    }

    function openMarket(uint256 marketID) external onlyOwner returns (bool) {
        require(marketExists[marketID], "Market is not exists, create first!");

        market[marketID].isOpened = true;
        return true;
    }

    function closeMarket(uint256 marketID) external onlyOwner returns (bool) {
        require(marketExists[marketID] && market[marketID].isOpened == true, "Market is not opened");
        market[marketID].isOpened = false;
        return true;
    }
    function removeMarket(uint256 marketID) external onlyOwner returns (bool) {
        require(marketExists[marketID] && market[marketID].isOpened == false, "Market is not closed");

        // Need settle logics in here (TODO)
        return true;
    }

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
    // 3. User need to deposit balance for purchasing

    /*
        struct TokenItemInfo {
            bool isForAuction;
            address lastOwner;
            address lastParticipant;    // last changed auction participant address
            uint256 deadline;           // If this is for auction
            uint256 cost;
        }
        struct MarketInfo {
            uint256 marketID;
            bool isOpened;
            mapping(uint256 => TokenItemInfo) tokenList;
        }
    */

    function applyItem(address _owner, uint256 token, uint256 marketId, uint256 cost) external onlyCore isMarketOpen(marketId) returns (bool) {
        MarketInfo storage marketInfo = market[marketId];
        TokenItemInfo storage item = marketInfo.tokenList[token];

        if (item.lastOwner != address(0)) {
            emit AlreadyApply(_owner, token);
            return false;
        }

        item.isForAuction = false;
        item.lastOwner = _owner;
        item.lastParticipant = address(0);
        item.deadline = 0x00;               // deadline field does not used
        item.cost = cost;

        emit ApplyItem(_owner, token, cost);
        return true;
    }

    function changeItemCost(
        address _owner, uint256 token, uint256 marketId, uint256 newCost
    ) external onlyCore isMarketOpen(marketId) returns (bool) {
        MarketInfo storage marketInfo = market[marketId];
        TokenItemInfo storage item = marketInfo.tokenList[token];

        require(item.lastOwner == _owner, "This token is not your token");
        item.cost = newCost;

        emit ChangeItemCost(token, newCost);
        return true;
    }

    function deleteItem(
        address _owner, uint256 token, uint256 marketId
    ) external onlyCore isMarketOpen(marketId) returns (bool) {
        MarketInfo storage marketInfo = market[marketId];
        TokenItemInfo storage item = marketInfo.tokenList[token];

        require(item.lastOwner == _owner, "This token is not your token");
        delete marketInfo.tokenList[token];

        emit DeleteItem(_owner, token);
        return true;
    }

    function purchase(uint256 token, uint256 marketId) external payable onlyCore isMarketOpen(marketId) returns (uint256) {
        MarketInfo storage marketInfo = market[marketId];
        TokenItemInfo storage item = marketInfo.tokenList[token];

        require(item.cost == msg.value, "You can't purchase, need more values");
        userDepositedBalances[item.lastOwner] += msg.value;

        delete marketInfo.tokenList[token];
        return token;
    }

    // Getter & Setter
    function getUserBalanceOnMarket(address user) external view returns (uint256) {
        return userDepositedBalances[user];
    }
}