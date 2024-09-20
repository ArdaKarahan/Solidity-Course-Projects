//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SharedWallet {

    event allowanceChanged(address indexed changed, address indexed gotChanged, bool setTo);
    event withdrawalSent(address indexed from, address indexed to, uint amount);
    event depositSent(address indexed from, uint amount);

    struct Transaction {
        uint amount;
        uint timestamp;
    }

    struct Account {
        uint totalMoney;
        uint numOfDeposits;
        uint numOfWithdrawals;
        uint numPeopleAllowed;
        
        mapping(uint => Transaction) deposits;
        mapping(uint => Transaction) withdrawals;
        mapping(uint => address) peopleAllowed;
        mapping(address => bool) isAllowed;
    }

    mapping(address => Account) accounts;

    //---------------------------------------------------------------------------------------------------------

    address owner;

    constructor() {
        owner = msg.sender;
    }

    //----------------------------------------------------------------------------------------------------------

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    modifier ownerAndAllowed() {
        require(msg.sender == owner || accounts[owner].isAllowed[msg.sender] == true, "You are not the owner and you are not allowed");
        _;
    }

    //-----------------------------------------------------------------------------------------------------------

    function setAllowed(address address_) public onlyOwner {

        accounts[owner].peopleAllowed[accounts[owner].numPeopleAllowed] = address_;
        accounts[owner].numPeopleAllowed++;

        accounts[owner].isAllowed[address_] = true;

        emit allowanceChanged(owner, address_, true);
    }

    function setNotAllowed(address address_) public ownerAndAllowed{
        require(accounts[owner].isAllowed[address_] == true, "This person is already not allowed");
        
        accounts[owner].isAllowed[address_] = false;

        emit allowanceChanged(owner, address_, false);
    }

    function checkAlloweds(uint which_) public view returns(address, bool){
        
        return (accounts[owner].peopleAllowed[which_], accounts[owner].isAllowed[accounts[owner].peopleAllowed[which_]]);
    }

    //-------------------------------------------------------------------------------------------------------------------------

    function depositMoney() public payable ownerAndAllowed {

        uint balanceRecieved = msg.value;

        accounts[owner].totalMoney += balanceRecieved;
        
        Transaction memory transaction;
        transaction = Transaction(balanceRecieved, block.timestamp);
        accounts[owner].deposits[accounts[owner].numOfDeposits] = transaction;

        accounts[owner].numOfDeposits++;

        emit depositSent(msg.sender, msg.value);
    }

    function withdrawMoney(address payable to_, uint amount_) public ownerAndAllowed {
        require(accounts[owner].totalMoney >= amount_, "Your balance is not enough");
        
        accounts[owner].totalMoney -= amount_;

        Transaction memory transaction;
        transaction = Transaction(amount_, block.timestamp);
        accounts[owner].withdrawals[accounts[owner].numOfWithdrawals] = transaction;

        accounts[owner].numOfWithdrawals++;

        to_.transfer(amount_);
        accounts[to_].totalMoney += amount_;

        emit withdrawalSent(msg.sender, to_, amount_);
    }

    function getBalance(address from_) public view returns(uint) {
        return accounts[from_].totalMoney;
    }

    receive() external payable { }
}