// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface INFTImplementation {
    struct MetaData {
        uint256 unique_id;
    }

    struct TokenMetadata {
        address owner;
        MetaData[] stored;
        mapping(uint256 => bool) ids;
    }

    function mint(address user, MetaData calldata data) external returns(bool);
    function burn(address user, uint256 unique_id) external returns(bool);

    function changeOwner(address user) external;
    function addMinter(address minter) external;
    function removeMinter(address minter) external;
}