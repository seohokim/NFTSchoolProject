// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

abstract contract IDepositPool {
    // 풀을 생성하기 위한 코드는 그다지 필요하지 않음
    // 여기서 필요한 기능은 그저 자금을 관리하기 위한 관리용 메서드, API들만 있으면 충분함
    uint256 public totalBalance;
    mapping(address => uint256) internal userDepositedBalance;

    function addDeposit(address from, uint256 amount) virtual public payable;
    function removeDeposit(address from, uint256 amount) virtual public payable;

    function getUserBalance(address from) virtual public view returns(uint256);
}