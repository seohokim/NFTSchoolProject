// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Import this file to use console.log
import "hardhat/console.sol";

import "./interfaces/INFTImplementation.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFTImplementation is INFTImplementation, AccessControl, ERC721("OurNFT", "ONFT") {
    using Counters for Counters.Counter;

    // Class member variables section
    Counters.Counter public currentTokenID;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER");

    // Whoever can minting over than MAXIMUM_TOKEN_ID value ? (Impossible)
    uint256 public constant MAXIMUM_TOKEN_ID = 10000000000000000000000;
    uint256 public deadline = 7 days;

    mapping(address => TokenMetadata) private metadata;
    PendingMetadata[] pendingQueue;

    // Modifiers and Events
    modifier onlyAdmin(address sender) {
        require(hasRole(DEFAULT_ADMIN_ROLE, sender), "YOU ARE NOT ADMIN");
        _;
    }

    modifier onlyMinter(address sender) {
        require(hasRole(MINTER_ROLE, sender), "YOU ARE NOT MINTER");
        _;
    }

    modifier onlyBurner(address sender) {
        require(hasRole(BURNER_ROLE, sender), "YOU ARE NOT BURNER");
        _;
    }

    constructor(address minter) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, minter);
    }

    // Implementation for Users
    // TODO
    // 1. Basic Minting, Burning implementation
    // 2. Basic Transferring implementation
    // 3. Auction implementation
    function mint(address user, MetaData calldata data) external onlyMinter(msg.sender) returns(bool) {
        // Minting with corresponding initialize fee (0.00001 ether)
        // Just for real network deploying, not development phase
        // require(msg.value >= 0.00001 ether, "Need at least 0.00001 ether for minting");
        // First, check this is first minting on target user
        TokenMetadata storage metaData = metadata[user];
        if (metaData.owner == address(0)) {
            // This is first minting process
            metaData.owner = address(user);
        }
        require(metaData.ids[data.unique_id] != true, "That's unique_id already exists");
        metaData.ids[data.unique_id] = true;
        metaData.stored.push(data);

        _mint(user, data.unique_id);                // Afterwards, should change to Counter (auto increments)
        return true;
    }

    function burn(address user, uint256 unique_id) external returns(bool) {
        require(msg.sender == user, "You can't burn this token");
        TokenMetadata storage metaData = metadata[user];
        
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
        return true;
    }

    function burn_pending(uint256 token_id) external returns (bool) {
        TokenMetadata storage metaData = metadata[msg.sender];
        uint256 tokenIndex = _findTokenID(metaData, token_id);

        require(tokenIndex != uint256(MAXIMUM_TOKEN_ID), "Token ID issue");
        require(ownerOf(token_id) == address(msg.sender), "OWNERSHIP ISSUE");

        // Need to check this is already in pending queue
        if (_isPending(token_id)) {
            return false;
        }
        
        // Remove from user's Metadata, and insert into Pending Queue
        pendingQueue.push(PendingMetadata(
            token_id,
            msg.sender,
            metaData.stored[tokenIndex],
            block.timestamp
        ));

        // Delete information from original list
        metaData.ids[token_id] = false;
        metaData.stored[tokenIndex] = metaData.stored[metaData.stored.length - 1];
        metaData.stored.pop();

        return true;
    }

    // Transfer ownership of each NFT items
    function transfer_ownership(address user, uint256 token_id) external returns (bool) {
        TokenMetadata storage metaData = metadata[user];
        uint256 tokenIndex = _findTokenID(metaData, token_id);

        require(tokenIndex != uint256(MAXIMUM_TOKEN_ID), "Token ID does ont exists");
        require(ownerOf(token_id) == address(msg.sender), "OWNERSHIP ISSUE");

        if (_isApprovedOrOwner(user, token_id) == false) {
            approve(user, token_id);
        }
        safeTransferFrom(address(msg.sender), user, token_id);
        return true;
    }
    

    // 

    // private functions
    function _findTokenID(TokenMetadata storage _metadata, uint256 unique_id) private view returns (uint256) {
        for (uint256 i = 0; i < _metadata.stored.length; i++) {
            if (_metadata.stored[i].unique_id == unique_id) {
                return i;
            }
        }
        return uint256(MAXIMUM_TOKEN_ID);
    }

    function _isPending(uint256 token_id) private view returns (bool) {
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

    // Admin Functions

    // Accepting request onlyOwner
    function acceptRequest() external onlyAdmin(msg.sender) returns (uint256) {
        uint256 accepted = 0;
        uint256 currentTime = block.timestamp;

        for (uint256 i = pendingQueue.length - 1; i >= 0; i--) {
            PendingMetadata storage pending = pendingQueue[i];

            if (currentTime >= pending.requestedTime + deadline) {
                pendingQueue[i] = pendingQueue[pendingQueue.length - 1];

                pendingQueue.pop();
                accepted += 1;
            }
        }
        return accepted;
    }

    // Restore pending element
    function restoreMetadata(address user, uint256 tokenId) public onlyAdmin(msg.sender) returns (bool) {
        uint256 index = _findPendingMetadata(tokenId);
        
        if (index == type(uint256).max) {
            return false;
        }

        // Restore data
        TokenMetadata storage metaData = metadata[user];
        metaData.ids[tokenId] = true;
        metaData.stored.push(MetaData(
            tokenId
        ));

        // Remove from pending queue
        pendingQueue[index] = pendingQueue[pendingQueue.length - 1];
        pendingQueue.pop();

        return true;
    }

    // Admin organization functions

    function changeOwner(address user) external onlyAdmin(msg.sender) {
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole(DEFAULT_ADMIN_ROLE, user);
    }

    function addMinter(address minter) external onlyAdmin(msg.sender) {
        grantRole(MINTER_ROLE, minter);
    }

    function removeMinter(address minter) external onlyAdmin(msg.sender) {
        renounceRole(MINTER_ROLE, minter);
    }

    function supportsInterface(bytes4 interfaceId) public view override(AccessControl, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // Getter & Setter
}