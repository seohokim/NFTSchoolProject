// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";

import "../interfaces/IOwnableCustom.sol";

import "../utils/Util.sol";


contract OwnableCustom is AccessControl, IOwnableCustom {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER");
    bytes32 public constant ALLOW_ROLE = keccak256("ALLOW");

    address private owner;

    function getOwner() external view returns (address) {
        return owner;
    }

    // Modifers area
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

    modifier onlyAllowed(address contr) {
        require(hasRole(ALLOW_ROLE, contr), "YOU ARE NOT ALLOWED");
        _;
    }

    modifier adminOrContract(address contr) {
        require(msg.sender == address(contr) ||
                msg.sender == owner, "Admin or Pending Queue only can call this");
        _;
    }

    function initializePermission(address minter, address burner) public {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, minter);
        _setupRole(BURNER_ROLE, burner);

        owner = address(msg.sender);

        emit InitializePermission(minter, burner);
    }

    // Functions area

    function changeOwner(address user) external onlyAdmin(msg.sender) {
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole(DEFAULT_ADMIN_ROLE, user);

        owner = address(user);
        emit ChangeOwner(user);
    }

    function addAllowedContract(address contr) public onlyAdmin(msg.sender) {
        require(Util.isContract(contr), "Parameter must be Contract address, not user");
        grantRole(ALLOW_ROLE, contr);
    }

    function addMinter(address minter) external onlyAdmin(msg.sender) {
        grantRole(MINTER_ROLE, minter);

        emit AddMinter(minter);
    }

    function removeMinter(address minter) external onlyAdmin(msg.sender) {
        renounceRole(MINTER_ROLE, minter);

        emit RemoveMinter(minter);
    }

    // Getter & Setter
}