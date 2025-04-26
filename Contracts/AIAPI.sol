//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/*
contract FreelanceArbitration {
    address public client;
    address public developer;
    uint public stakeAmount;
    bool public disputeRaised = false;
    address public aiVerifier;  // Bu adres GPT API sonucunu gönderen backend olacak

    constructor(address _developer, address _aiVerifier) payable {
        client = msg.sender;
        developer = _developer;
        stakeAmount = msg.value;  // Müşteri ödeme yapar
        aiVerifier = _aiVerifier;  // Backend sunucunun cüzdan adresi
    }

    function raiseDispute() public {
        require(msg.sender == client || msg.sender == developer, "Yetkiniz yok.");
        disputeRaised = true;
        // GPT API değerlendirmesi yapılacak
    }

    // Backend, GPT API sonucunu gönderir
    function resolveDispute(uint similarityScore) public {
        require(msg.sender == aiVerifier, "Sadece AI doğrulayıcı sonuç gönderebilir.");
        require(disputeRaised, "Anlaşmazlık yok.");

        if (similarityScore >= 70) {
            payable(developer).transfer(stakeAmount);
        } else {
            payable(client).transfer(stakeAmount);
        }
        disputeRaised = false;
    }
}*/