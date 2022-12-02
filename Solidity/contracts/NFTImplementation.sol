// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Import this file to use console.log
import "hardhat/console.sol";

import "./interfaces/INFTImplementation.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


import "./libs/DataTypes.sol";
import "./utils/OwnableCustom.sol";
import "./libs/PendingQueue.sol";
import "./libs/MarketPlace.sol";
import "./governance/Governance.sol";

import "./interfaces/IDepositPool.sol";

contract NFTImplementation is INFTImplementation, OwnableCustom, ERC721("OurNFT", "ONFT") {
    using Counters for Counters.Counter;

    // Class member variables section
    address private owner;
    Counters.Counter public currentTokenID;
    // Whoever can minting over than MAXIMUM_TOKEN_ID value ? (Impossible)
    uint256 public constant MAXIMUM_TOKEN_ID = type(uint256).max;

    /*
    struct TokenMetadata {
        address owner;
        MetaData[] stored;
        mapping(uint256 => bool) ids;
    }
    */
    mapping(address => DataTypes.TokenMetadata) public metadata;

    // Contract area
    // * Have relationship with Core NFT Contract
    PendingQueue public pdQueueCon;
    MarketPlace public marketPlace;
    Governance public governance;

    IDepositPool public depositPool;

    constructor(address minter) {
        address _minter = minter;
        address _burner = msg.sender;

        owner = address(msg.sender);

        // Initialize Pending Queue
        pdQueueCon = new PendingQueue();
        marketPlace = new MarketPlace();
        governance = new Governance(msg.sender, address(this));

        // Initializing
        initializePermission(_minter, _burner);
        marketPlace.initializeMarketPlace(msg.sender);
        _initializeAllowedContract();

        emit CoreInitialize(address(pdQueueCon), address(marketPlace), address(governance));
    }

    function _initializeAllowedContract() private onlyAdmin(msg.sender) {
        addAllowedContract(address(pdQueueCon));
        addAllowedContract(address(marketPlace));
        addAllowedContract(address(governance));
    }

    function setDepositPool(address depositPoolAddress) public onlyAdmin(msg.sender) {
        depositPool = IDepositPool(depositPoolAddress);
    }

    function isExists(address user, uint256 tokenID) public view returns (bool) {
        return metadata[user].ids[tokenID] == true;
    }

    // Implementation for Users
    // 1. Basic Minting, Burning implementation
    // 2. Basic Transferring implementation
    // 3. Auction implementation
    function mint(address user, DataTypes.MetaData calldata data) external payable onlyMinter(msg.sender) returns(bool) {
        // Minting with corresponding initialize fee (0.00001 ether)
        // Just for real network deploying, not development phase

        // 만약 Governance에서 불법적인 사용자를 reporting 한 것이 1회 이상이고 이게 실제로 악의적인 사용자를 리포트를 한 경우면
        // 1회 수수료를 면제할 수 있도록 해줌
        require(governance.popReportingCounter(msg.sender) >= 1 || msg.value >= 0.00001 ether, "Need at least 0.00001 ether for minting");
        depositPool.addDeposit(address(msg.sender), msg.value);         // Deposit to DepositPool for support liquidity

        // First, check this is first minting on target user
        DataTypes.TokenMetadata storage metaData = metadata[user];
        if (metaData.owner == address(0)) {
            // This is first minting process
            metaData.owner = address(user);
        }
        require(metaData.ids[data.unique_id] != true, "That's unique_id already exists");
        metaData.ids[data.unique_id] = true;
        metaData.stored.push(data);

        _mint(user, data.unique_id);                // Afterwards, should change to Counter (auto increments)
        emit Mint(user, data.unique_id);

        return true;
    }

    /*
    function burn(address user, uint256 unique_id) external returns(bool) {
        require(msg.sender == user, "You can't burn this token");
        DataTypes.TokenMetadata storage metaData = metadata[user];
        
        if (metaData.owner == address(0)) {
            return false;
        }
        require(metaData.ids[unique_id] == true, "This id is not exists");
        uint256 tokenIndex = _findTokenID(metaData, unique_id);

        if (tokenIndex == uint256(MAXIMUM_TOKEN_ID)) {
            return false;
        } else {
            metaData.ids[unique_id] = false;
            metaData.stored[tokenIndex] = metaData.stored[metaData.stored.length - 1];
            metaData.stored.pop();
        }
        _burn(unique_id);

        emit Burn(user, unique_id);
        return true;
    }
    */

    function burningByAdmin(uint256 tokenId) external 
        adminOrContract(address(pdQueueCon)) returns (bool) {
        _burn(tokenId);
        return true;
    }

    function requestBurning(uint256 token_id) external returns (bool) {
        DataTypes.TokenMetadata storage metaData = metadata[msg.sender];
        uint256 tokenIndex = _findTokenID(metaData, token_id);

        require(tokenIndex != uint256(MAXIMUM_TOKEN_ID), "Token ID issue");
        require(ownerOf(token_id) == address(msg.sender), "OWNERSHIP ISSUE");

        // Need to check this is already in pending queue
        if (pdQueueCon.isPending(token_id)) {
            return false;
        }
        
        // Remove from user's Metadata, and insert into Pending Queue
        pdQueueCon.push(DataTypes.PendingMetadata(
            token_id,
            msg.sender,
            metaData.stored[tokenIndex],
            block.timestamp
        ));

        // Delete information from original list
        metaData.ids[token_id] = false;
        metaData.stored[tokenIndex] = metaData.stored[metaData.stored.length - 1];
        metaData.stored.pop();

        emit RequestPending(msg.sender, token_id);

        return true;
    }

    // Transfer ownership of each NFT items
    function transferOwnership(address user, uint256 token_id) external returns (bool) {
        DataTypes.TokenMetadata storage metaData = metadata[msg.sender];
        uint256 tokenIndex = _findTokenID(metaData, token_id);

        require(tokenIndex != uint256(MAXIMUM_TOKEN_ID), "Token ID does ont exists");
        require(ownerOf(token_id) == address(msg.sender), "OWNERSHIP ISSUE");

        _removeFromMetadata(msg.sender, token_id);
        _addToMetadata(user, token_id);

        if (_isApprovedOrOwner(user, token_id) == false) {
            approve(user, token_id);
        }
        _safeTransfer(address(msg.sender), user, token_id, "");
        return true;
    }

    // private functions
    function _findTokenID(DataTypes.TokenMetadata storage _metadata, uint256 unique_id) private view returns (uint256) {
        for (uint256 i = 0; i < _metadata.stored.length; i++) {
            if (_metadata.stored[i].unique_id == unique_id) {
                return i;
            }
        }
        return uint256(MAXIMUM_TOKEN_ID);
    }

    function _addToMetadata(address user, uint256 tokenID) private {
        DataTypes.TokenMetadata storage metaData = metadata[user];

        if (metaData.owner == address(0)) {
            metaData.owner = user;
        }
        metaData.ids[tokenID] = true;
        metaData.stored.push(DataTypes.MetaData(
            tokenID
        ));
    }

    function _removeFromMetadata(address user, uint256 tokenID) private {
        DataTypes.TokenMetadata storage metaData = metadata[user];
        uint256 tokenIndex = _findTokenID(metaData, tokenID);

        metaData.ids[tokenID] = false;

        delete metaData.stored[tokenIndex];
        metaData.stored[tokenIndex] = metaData.stored[metaData.stored.length - 1];
        metaData.stored.pop();
    }

    // Admin Functions

    // Accepting request onlyOwner
    function acceptRequest() external onlyAdmin(msg.sender) returns (uint256) {
        return pdQueueCon.acceptRequest();
    }

    // Restore pending element
    function restoreMetadata(address user, uint256 tokenId) external onlyAdmin(msg.sender) returns (bool) {
        uint256 index = pdQueueCon.findPendingMetadata(tokenId);
        
        if (index == type(uint256).max) {
            return false;
        }

        // Restore data
        DataTypes.TokenMetadata storage metaData = metadata[user];
        metaData.ids[tokenId] = true;
        metaData.stored.push(DataTypes.MetaData(
            tokenId
        ));

        // Remove from pending queue
        pdQueueCon.remove(index);
        return true;
    }

    function supportsInterface(bytes4 interfaceId) public view override(AccessControl, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // Delete contract logics
    function terminate() payable external {
        selfdestruct(payable(owner));
    }

    // Related with MarketPlace contract
    function transferForMarket(address user, uint256 tokenID) external onlyAllowed(msg.sender) {
        _safeTransfer(ownerOf(tokenID), user, tokenID, "");
    }

    function depositToMarket(uint256 amount) external {
        // require(msg.value >= amount, "No enough value for amount");
        marketPlace.deposit(msg.sender, amount);
        // marketPlace.deposit{value: amount}(msg.sender, amount);
    }

    function withdrawFromMarket(uint256 amount) external {
        marketPlace.withdraw(msg.sender, amount);
    }

    function startAuction(uint256 marketID, uint256 tokenID, uint256 startCost) external {
        marketPlace.startAuction(msg.sender, tokenID, marketID, startCost);
    }

    function endAuction(uint256 marketID, uint256 tokenID) external {
        marketPlace.endAuction(msg.sender, tokenID, marketID);
    }

    function suggestToAuction(uint256 marketID, uint256 tokenID, uint256 suggestCost) external returns (bool) {
        return marketPlace.suggest(msg.sender, tokenID, marketID, suggestCost);
    }

    // For selling mechanism between users
    function applyItem(uint256 marketID, uint256 tokenID, uint256 cost) external returns (bool) {
        return marketPlace.applyItem(msg.sender, tokenID, marketID, cost);
    }

    function changeItemCost(uint256 marketID, uint256 tokenID, uint256 newCost) external returns (bool) {
        return marketPlace.changeItemCost(msg.sender, tokenID, marketID, newCost);
    }

    function deleteItem(uint256 marketID, uint256 tokenID) external returns (bool) {
        return marketPlace.deleteItem(msg.sender, tokenID, marketID);
    }

    function purchaseItem(uint256 marketID, uint256 tokenID) external payable returns (bool) {
        uint256 tokenNum = marketPlace.purchase(tokenID, marketID);
        tokenNum;
        // tokenNum transfer to purchasing user
        // TODO
        return true;
    }
}