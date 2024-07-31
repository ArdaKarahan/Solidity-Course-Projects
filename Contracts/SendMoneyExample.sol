// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.26;

contract SendWithdrawMoney {


    uint public balanceRecieved;

    function deposit() public payable {
        balanceRecieved += msg.value;
    }

    function getContractBalance() public view returns(uint) {
        return address(this).balance;
    }

    function withdrawAll() public {
        address payable to = payable (msg.sender);
        to.transfer(getContractBalance());
    }

    function withdrawAddress(address payable to) public {
        to.transfer(getContractBalance());
    }
}