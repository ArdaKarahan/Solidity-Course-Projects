// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.26;

contract BlockchainMessenger {

    uint public cheangeCounter;

    address public owner;

    string public message;

    constructor() {
        owner = msg.sender;
    }

    function updateMessage(string memory newMesagge) public {
        if (msg.sender == owner) {
            message = newMesagge;
            cheangeCounter++;
        }
    }
}