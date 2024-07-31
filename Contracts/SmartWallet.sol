// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.26;

/*contract Consumer {

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function deposit() public payable {}
    
}
//This contract is to test the "SmartContractWallet" contract. You can deposit some ethers,
//take the input of the transaction and put it in the payload section when you want to
//use Transfer function.
*/

contract SmartContractWallet {

    address payable public owner;

    mapping (address => uint) public allowance;
    mapping (address => bool) public isAllowedToSend;
    mapping (address => bool) public guardians;
    mapping (address => mapping(address => bool)) nextOwnerGuardianVoteBool;

    address payable nextOwner;
    uint guardiansResetCount;
    uint public constant confirmationFromGuardiansForReset = 3;

    constructor() {
        owner = payable(msg.sender);
    }

    function setGuardian(address guardian_, bool isGuardian) public {
        require(msg.sender == owner, "you are not the owner, aborting!");
        guardians[guardian_] = isGuardian;
    }

    function proposeNewOwner(address payable newOwner_) public {
        require(guardians[msg.sender], "You are not guardian of this wallet, aborting!");
        require(nextOwnerGuardianVoteBool[newOwner_][msg.sender] == false, "You already voted, aborting!");
        if(newOwner_ != nextOwner) {
            nextOwner = newOwner_;
            guardiansResetCount = 0;
        }

        guardiansResetCount++;

        if(guardiansResetCount >= confirmationFromGuardiansForReset) {
            owner = nextOwner;
            nextOwner = payable (address(0));
        }
    }

    function setAllowance(address for_, uint amount_) public {
        require(msg.sender == owner, "you are not the owner, aborting!");
        allowance[for_] = amount_;

        if (amount_ > 0) {
            isAllowedToSend[for_] = true;
        } else {
            isAllowedToSend[for_] = false;
        }
    }

    function Transfer(address payable to_, uint amount_, bytes memory payload) public returns(bytes memory){
        require(amount_ <= address(this).balance, "Can't send more than the contract owns, aborting.");
        if(msg.sender == owner) {
            require(amount_ <= allowance[msg.sender], "You are trying to send more than you are allowed to, aborting!");
            require(isAllowedToSend[msg.sender], "You are not allowed to send anything on this smart contract, aborting!");

            allowance[msg.sender] -= amount_; //did not understand this part
        }

        (bool success, bytes memory returnData) = to_.call{value: amount_}(payload);
        require(success, "Aborting, call was not successful");
        return returnData;
    }

    receive() external payable { }
}