//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract LuckyNumber {
    uint myNumber;
    address payable owner;

    constructor() {
        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner of this contract");
        _;
    }

    modifier enoughMoney() {
        require(msg.value > 1, "Not enough balance");
        _; 
    }

    function setLuckyNumber(uint _luckyNumber) public onlyOwner {
        myNumber = _luckyNumber;
    }

    function getLuckyNumber() public view returns(uint) {
        return myNumber;
    }

    function getOwner() public view returns(address) {
        return owner;
    }

    function changeLuckyNumber(uint _luckyNumber) external payable enoughMoney {
        myNumber = _luckyNumber;
        owner.transfer(msg.value);
    }
}