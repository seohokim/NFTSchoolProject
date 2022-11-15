// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../libs/DataTypes.sol";

interface INFTImplementation {
    event CoreInitialize(address pendingQueue);
    event Mint(address user, uint256 tokenId);
    event Burn(address user, uint256 tokenId);
    event RequestPending(address user, uint256 tokenId);

    function mint(address user, DataTypes.MetaData calldata data) external returns(bool);
    // function burn(address user, uint256 unique_id) external returns(bool);
    function burningByAdmin(uint256 tokenId) external returns (bool);
    function transferOwnership(address user, uint256 token_id) external returns (bool);


    function acceptRequest() external returns (uint256);
    function restoreMetadata(address user, uint256 tokenId) external returns (bool);
}