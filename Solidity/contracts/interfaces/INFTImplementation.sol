// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../libs/DataTypes.sol";

interface INFTImplementation {
    event CoreInitialize(address pendingQueue, address marketPlace, address governance);
    event Mint(address user, uint256 tokenId);
    event Burn(address user, uint256 tokenId);
    event RequestPending(address user, uint256 tokenId);
    event Burned(address owner, uint256 tokenID, uint256 timestamp);

    function mint(DataTypes.MetaData calldata data) external payable returns(bool);
    // function burn(address user, uint256 unique_id) external returns(bool);
    function burningByAdmin(uint256 tokenId) external returns (bool);
    function transferOwnership(address user, uint256 token_id) external returns (bool);


    function acceptRequest() external returns (uint256);
    function restoreMetadata(address user, uint256 tokenId) external returns (bool);
    function terminate() payable external;

    // For MarketPlace
    function transferForMarket(address user, uint256 tokenID) external;
    function depositToMarket(uint256 amount) external;
    function withdrawFromMarket(uint256 amount) external;
    function startAuction(uint256 marketID, uint256 tokenID, uint256 startCost) external;
    function endAuction(uint256 marketID, uint256 tokenID) external;
    function suggestToAuction(uint256 marketID, uint256 tokenID, uint256 suggestCost) external returns (bool);
}