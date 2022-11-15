// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

library DataTypes {
    struct MetaData {
        uint256 unique_id;
    }

    struct TokenMetadata {
        address owner;
        MetaData[] stored;
        mapping(uint256 => bool) ids;
    }

    struct PendingMetadata {
        uint256 id;
        address owner;
        MetaData info;
        uint256 requestedTime;
    }
}