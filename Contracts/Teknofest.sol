//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ChainLance {

    uint public balanceRecieved;
    address payable public AIaddress;
    uint public numOfWorks;
    uint public numOfAgreements;
    mapping(address => Account) public accounts;
    mapping(bytes32 => OfferedWork) public offeredWorks; //This one is for keeping track of all offered works
    mapping(bytes32 => Agreement) public agreements; //This one is to keep track of every agreement made
    mapping(bytes32 => mapping(uint => address)) candidates; //This one is for keeping track of all candidates for each work offered
    mapping(bytes32 => mapping(address => mapping(address => bool))) middleManVotePool; //mapping(agreementHash => mapping(middlemansAddress => mapping(employer's or employee's address => voted)))
    mapping(bytes32 => mapping(address => uint)) middleManVoteNumber; //mapping(agreementHash => mapping(middlemansAddress => mapping(employer's or employee's address => voted)))
    mapping(bytes32 => mapping(uint => address)) askedMiddlemans; //All the middlemans asked for each agreement

    event accountCreated(address indexed acountAddress, Account account);
    event workOffered(bytes32 workHash, OfferedWork offeredWork);
    event workDeleted(OfferedWork offeredWork);
    event appliedToWork(address indexed applicant, OfferedWork offeredWork);
    event reqruitedEmployee(bytes32 indexed agreementHash, Agreement agreement);
    event suggestedMiddleman(address suggested, address middleman, Agreement agreement);
    event askedMiddleman(Agreement agreement, address middleman);
    event middlemanValidated(Agreement agreement);
    event employeeDone(bool employeeDone);
    event employerValidated(bool employerValidated);
    event disputeRaised(Agreement agreement);
    event disputeResolved(Agreement agreement);

    constructor() {
        AIaddress = payable(msg.sender);
    }

    struct Account {
        bool isEmployer;
        bool isEmployee;
        bool isMiddleman;
        bool registered;
    }

    struct OfferedWork {
        uint nonce;
        address employer;
        uint numOfCandidates;
        uint amountToStake;
        bool isSealed; //If someone got reqruited for the offered work or if the work is deleted, isSealed value will be true
    }

    struct Agreement {
        uint nonce;
        address employer;
        address employee;
        address middleman;
        uint amountForEmployee;
        uint askedMiddlemanNumber;
        bool employeeDone; //Is employee done with the given task
        bool employerValidate; //Did employer validate the received work
        bool disputeRaised; //If one side of the agreement raised a dispute
        bool resolveCheck; //If employer did not validate, employee can ask AI if the work is done as intended and if he/she should receive the escrowed money
    }

    modifier onlyEmployer{
        require(accounts[msg.sender].isEmployer == true, "You need to be an employer to do that");
        _;
    }

    modifier onlyEmployee{
        require(accounts[msg.sender].isEmployee == true, "You need to be an employee to do that");
        _;
    }

    /* !!!Bütün fonksiyonlar nonReenterant olarak işaretlenecek!!! */

    function newAccount(bool isEmployee_, bool isEmployer_,bool isMiddleman_) public {
        uint accountBools;

        if (isEmployee_) {
            accountBools++;
        }
        if (isEmployer_) {
            accountBools++;
        }
        if (isMiddleman_) {
            accountBools++;
        }

        require(accountBools == 1, "Please choose one option");
        require(accounts[msg.sender].registered == false, "You are already registered");

        Account memory account;
        account.isMiddleman = isMiddleman_;
        account.isEmployer = isEmployer_;
        account.isEmployee = isEmployee_;
        account.isMiddleman = isMiddleman_;
        account.registered = true;
        accounts[msg.sender] = account;


        emit accountCreated(msg.sender, account);
    }

    function offerWork() public payable onlyEmployer {
        require(msg.value >= 10 ** 12, "Insufficient stake amount");

        OfferedWork memory offeredWork;
        offeredWork.employer = msg.sender;

        uint staked = msg.value;
        offeredWork.amountToStake = staked;
        balanceRecieved += staked;
        
        numOfWorks++;
        offeredWork.nonce = numOfWorks;
        bytes32 offeredWorkHash = keccak256(abi.encode(offeredWork));
        offeredWorks[offeredWorkHash] = offeredWork;

        emit workOffered(offeredWorkHash, offeredWork);
    }

    function deleteWork(bytes32 which_) public onlyEmployer {
        require(offeredWorks[which_].employer == msg.sender, "You are not the employer of this work");
        require(offeredWorks[which_].isSealed == false, "This task is now off");
        require(balanceRecieved >= offeredWorks[which_].amountToStake, "Not enough balance");

        uint amountToStake = offeredWorks[which_].amountToStake;
        offeredWorks[which_].isSealed = true;
        payable(msg.sender).transfer(amountToStake);

        emit workDeleted(offeredWorks[which_]);
    }

    function applyOfferedWork(bytes32 which_) public onlyEmployee {
        require(offeredWorks[which_].isSealed == false, "This task is now off");
        offeredWorks[which_].numOfCandidates++;
        candidates[which_][offeredWorks[which_].numOfCandidates] = msg.sender;

        emit appliedToWork(msg.sender, offeredWorks[which_]);
    }

    function getCandidates(bytes32 offeredWorkHash_, uint candidateNumber_) public view returns(address){
        require(offeredWorks[offeredWorkHash_].employer == msg.sender,"You are not the employer of this offered Work");

        return candidates[offeredWorkHash_][candidateNumber_];
    }

    function reqruitEmployee(bytes32 whichOffer_, uint whichCandidate_) public onlyEmployer {
        require(offeredWorks[whichOffer_].employer == msg.sender, "You are not the employer of this work");
        require(offeredWorks[whichOffer_].isSealed == false, "This task is now off");
        
        Agreement memory agreement;
        agreement.employer = msg.sender;
        agreement.employee =  candidates[whichOffer_][whichCandidate_];
        agreement.amountForEmployee = offeredWorks[whichOffer_].amountToStake;
        numOfAgreements++;
        agreement.nonce = numOfAgreements;

        bytes32 agreementHash = keccak256(abi.encode(agreement));
        agreements[agreementHash] = agreement;
        offeredWorks[whichOffer_].isSealed = true;

        emit reqruitedEmployee(agreementHash, agreement);
    }

    function suggestMiddleman(bytes32 whichAgreement_, address middleman_) public {
        require(agreements[whichAgreement_].employee == msg.sender || agreements[whichAgreement_].employer == msg.sender, "You are not allowed to suggest");
        require(middleManVotePool[whichAgreement_][middleman_][msg.sender] == false, "You already voted for this middleman");
        require(agreements[whichAgreement_].middleman == address(0), "You already have a middleman");
        require(accounts[middleman_].isMiddleman, "This address is not a middleman");

        middleManVotePool[whichAgreement_][middleman_][msg.sender] = true;
        middleManVoteNumber[whichAgreement_][middleman_]++;

        emit suggestedMiddleman(msg.sender, middleman_, agreements[whichAgreement_]);

        if(middleManVoteNumber[whichAgreement_][middleman_] == 2) {
            askMiddleman(whichAgreement_, middleman_);
        }
    }

    function askMiddleman(bytes32 whichAgreement_, address middleman_) private {
        require(agreements[whichAgreement_].employee == msg.sender || agreements[whichAgreement_].employer == msg.sender, "You are not allowed to set middleman");
        agreements[whichAgreement_].askedMiddlemanNumber++;
        askedMiddlemans[whichAgreement_][agreements[whichAgreement_].askedMiddlemanNumber] = middleman_;

        emit askedMiddleman(agreements[whichAgreement_], middleman_);
    }

    function getAskedMiddleman(bytes32 whichAgreement_, uint whichMiddleman_) public view returns(address) {
        return askedMiddlemans[whichAgreement_][whichMiddleman_];
    }

    function getMiddleman(bytes32 whichAgreement_) public view returns(address) {
        return agreements[whichAgreement_].middleman;
    }

    function middleManValidate(bytes32 whichAgreement_, uint whichMiddleman_) public {
        require(askedMiddlemans[whichAgreement_][whichMiddleman_] == msg.sender, "You are not asked to be the middleman of this agreement");
        agreements[whichAgreement_].middleman = msg.sender;

        emit middlemanValidated(agreements[whichAgreement_]);
    }

    function setEmployeeDone(bytes32 whichAgreement_) public {
        require(agreements[whichAgreement_].employee == msg.sender, "You are not the employee of this agreement");
        agreements[whichAgreement_].employeeDone = true;

        emit employeeDone(true);
    }

    function setEmployerValidate(bytes32 whichAgreement_) public {
        require(agreements[whichAgreement_].employer == msg.sender, "You are not the employer of this agreement");
        require(agreements[whichAgreement_].employeeDone == true, "The employee is not done with this task yet");

        agreements[whichAgreement_].employerValidate = true;
        uint amountToStake = agreements[whichAgreement_].amountForEmployee;
        payable(agreements[whichAgreement_].employee).transfer(amountToStake);
        balanceRecieved -= amountToStake;

        emit employerValidated(true);
    }

    function raiseDispute(bytes32 whichAgreement_) public {
        require(agreements[whichAgreement_].employee == msg.sender || agreements[whichAgreement_].employer == msg.sender, "You do not posses authority");

        agreements[whichAgreement_].disputeRaised = true;
        emit disputeRaised(agreements[whichAgreement_]);
    }

    /*
    The part where AI checking how much of the project is done located outside of the contract. Basically AI is going to
    check how many of the terms in the agreement is done and craeate a scoreboard. This will end up AI deciding if it should
    resolve the dispute or not and if it decides to resolve, it will invoke the resolveDispute function.
    */


    function resolveDispluteMiddleman(bytes32 whichAgreement_, uint employeePercent, uint employerPercent) public {
        require(msg.sender == agreements[whichAgreement_].middleman, "You are not allowed to resolve this dispute");
        require(agreements[whichAgreement_].disputeRaised == true, "There is no dispute raied in this agreement");
        require(agreements[whichAgreement_].resolveCheck == false, "This dispute has been resolved");
        require(employeePercent + employerPercent == 100, "Invalid percentages");

        agreements[whichAgreement_].resolveCheck = true;

        uint amountToStake = agreements[whichAgreement_].amountForEmployee;
        uint amountEmployee = (amountToStake * employeePercent) / 100;
        uint amountEmployer = (amountToStake * employerPercent) / 100;

        payable(agreements[whichAgreement_].employee).transfer(amountEmployee);
        payable(agreements[whichAgreement_].employer).transfer(amountEmployer);

        balanceRecieved -= amountToStake;

        emit disputeResolved(agreements[whichAgreement_]);
    }

    //OpenZeppelin'den onlyOwner modifier'ı kullanılacak
    function resolveDispluteAI(bytes32 whichAgreement_, address beneficiary) public {
        require(msg.sender == AIaddress, "You are not allowed to resolve this dispute");
        require(agreements[whichAgreement_].disputeRaised == true, "There is no dispute raied in this agreement");
        require(beneficiary == agreements[whichAgreement_].employee || beneficiary == agreements[whichAgreement_].employer, "The beneficiary is not an employee nor an employer of this agreement");
        require(agreements[whichAgreement_].resolveCheck == false, "This dispute has been resolved");
        
        agreements[whichAgreement_].resolveCheck = true;

        uint amountToStake = agreements[whichAgreement_].amountForEmployee;
        payable(beneficiary).transfer(amountToStake);

        balanceRecieved -= amountToStake;

        emit disputeResolved(agreements[whichAgreement_]);
    }

    receive() external payable { }

    fallback() external payable { }
}