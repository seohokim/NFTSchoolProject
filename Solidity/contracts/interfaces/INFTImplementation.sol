// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../libs/DataTypes.sol";

interface INFTImplementation {
    function mint(address user, DataTypes.MetaData calldata data) external returns(bool);
    function burn(address user, uint256 unique_id) external returns(bool);
}