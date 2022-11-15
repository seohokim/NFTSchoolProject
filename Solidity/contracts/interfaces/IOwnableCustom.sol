// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../libs/DataTypes.sol";

interface IOwnableCustom {
    event InitializePermission(address minter, address burner);
    event ChangeOwner(address user);
    event AddMinter(address user);
    event RemoveMinter(address user);

    function changeOwner(address user) external;
    function addMinter(address minter) external;
    function removeMinter(address minter) external;
    function getOwner() external view returns(address);
}