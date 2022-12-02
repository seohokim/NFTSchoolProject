// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../libs/DataTypes.sol";

struct Reported {
    address from;
    address target;
    bytes description;
}

interface IGovernance {
    function ban(address user, uint256 period) external returns (bool);
    function unban(address user) external returns (bool);
    function report(address from, address reported, bytes memory description) external payable;
    function out() external returns (Reported memory);
}