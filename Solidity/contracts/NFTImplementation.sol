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


contract NFTImplementation is INFTImplementation, OwnableCustom, ERC721("OurNFT", "ONFT") {
    using Counters for Counters.Counter;

    // Class member variables section
    address private owner;
    Counters.Counter public currentTokenID;
    // Whoever can minting over than MAXIMUM_TOKEN_ID value ? (Impossible)
    uint256 public constant MAXIMUM_TOKEN_ID = 10000000000000000000000;
    mapping(address => DataTypes.TokenMetadata) private metadata;

    // Contract area
    // * Have relationship with Core NFT Contract
    PendingQueue pdQueueCon;
    MarketPlace marketPlace;

    constructor(address minter) {
        address _minter = minter;
        address _burner = msg.sender;

        owner = address(msg.sender);

        initializePermission(_minter, _burner);

        // Initialize Pending Queue
        pdQueueCon = new PendingQueue();
        marketPlace = new MarketPlace();

        marketPlace.initializeMarketPlace();
        emit CoreInitialize(address(pdQueueCon));
    }

    // Implementation for Users
    // 1. Basic Minting, Burning implementation
    // 2. Basic Transferring implementation
    // 3. Auction implementation
    function mint(address user, DataTypes.MetaData calldata data) external onlyMinter(msg.sender) returns(bool) {
        // Minting with corresponding initialize fee (0.00001 ether)
        // Just for real network deploying, not development phase
        // require(msg.value >= 0.00001 ether, "Need at least 0.00001 ether for minting");
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
        DataTypes.TokenMetadata storage metaData = metadata[user];
        uint256 tokenIndex = _findTokenID(metaData, token_id);

        require(tokenIndex != uint256(MAXIMUM_TOKEN_ID), "Token ID does ont exists");
        require(ownerOf(token_id) == address(msg.sender), "OWNERSHIP ISSUE");

        if (_isApprovedOrOwner(user, token_id) == false) {
            approve(user, token_id);
        }
        safeTransferFrom(address(msg.sender), user, token_id);
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
}