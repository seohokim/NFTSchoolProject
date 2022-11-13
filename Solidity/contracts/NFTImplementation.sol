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
    function mint() external onlyMinter(msg.sender) returns(bool) {
        // Minting with corresponding initialize fee (0.00001 ether)
        
    }

    function burn() external onlyBurner(msg.sender) returns(bool) {

    }

    // Admin Functions
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