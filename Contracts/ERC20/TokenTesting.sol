//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

abstract contract ERC20 {
    function transferFrom(address from, address to, uint amount) public virtual returns(bool success);
    function decimals() public view virtual returns(uint);
}

contract TokenSale {

    uint tokenPriceInWei = 1 ether;

    ERC20 public token;
    address public tokenOwner;

    constructor(address _token) {
        tokenOwner = msg.sender;
        token = ERC20(_token);
    }

    function purchase() public payable {
        require(msg.value >= tokenPriceInWei, "Not enough money sent");
        uint tokensToTransfer = msg.value / tokenPriceInWei;
        uint remainder = msg.value - tokensToTransfer * tokenPriceInWei;
        token.transferFrom(tokenOwner, msg.sender, tokensToTransfer * 10 ** token.decimals());
        payable(msg.sender).transfer(remainder); //send the rest back

    }
}