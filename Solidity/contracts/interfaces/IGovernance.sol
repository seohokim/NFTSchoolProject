// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../libs/DataTypes.sol";

interface IGovernance {
    function ban(address user, uint256 period) external returns (bool);
    function unban(address user) external returns (bool);
}