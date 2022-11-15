// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

library Util {
    function isContract(address _addr) view external returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }
}