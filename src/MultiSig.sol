// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

contract MultiSig{

    // ERRORS   

    error NotOwner();
    error AlreadySignedTransactionRequest();
    error AlreadySignedOwnerRequest();
    error InvalidProposalIndex();
    error insufficientFunds();
    error InvalidRecipientAddress();
    error insufficientSignatures();
    error AlreadyOwner();

    // EVENTS

    event AddedOwner(address indexed AddedNewOwner);
    event TransactionExecuted(address indexed Recipient, uint256 Value);
    event proposedTransaction(address indexed Recipient, uint256 Value, address Proposer);
    event proposedOwner(address indexed ProposedOwner, address Proposer);
    event DeclinedOwnerProposal(address indexed DeclinedProposal, address Decliner);
    event DeclinedTransactionProposal(address indexed DeclinedProposalRecipient, uint256 DeclinedProposalValue, address Decliner);
    event SignedOwnerProposal(address indexed ProposedOwner, address Signer);
    event SignedTransactionProposal(address indexed Recipient, uint256 Value, address Signer);
    event Deposited(address indexed Sender, uint256 Value);

    struct Proposal{
        address to;
        uint256 value;
        address[] signatures;
    }

    address[] private s_owners;
    Proposal[]  private s_proposals;
    // Proposal[] private s_proposedOwners;
    mapping(address=> address[]) private s_proposedOwners;
    constructor() {
        s_owners.push(msg.sender);
    }

    function deposit() public payable onlyOwner {
        // Accepts ether deposits to the contract
        emit Deposited(msg.sender, msg.value);
    }

    function proposeTransaction(address to, uint256 value) public onlyOwner {

        if(to == address(0)) {
            revert InvalidRecipientAddress();
        }
        if(s_owners.length == 1) {

            if(value > address(this).balance) {
                revert insufficientFunds();
            }
            (bool success, ) = payable(to).call{value: value}("");
            require(success, "Transaction failed");
            emit TransactionExecuted(to, value);
            return;
        }

        s_proposals.push(Proposal({
            to: to,
            value: value,
            signatures: new address[](0)
        }));

        s_proposals[s_proposals.length - 1].signatures.push(msg.sender);
        emit proposedTransaction(to, value, msg.sender);
    }

    function proposeOwner(address newOwner) public onlyOwner {

        if(hasOwner(newOwner) || AlreadyProposed(newOwner)) {
            revert AlreadyOwner();
        }

        if(s_owners.length == 1) {
            s_owners.push(newOwner);
            emit AddedOwner(newOwner);
            return;
        }

        s_proposedOwners[newOwner] = new address[](0);
        s_proposedOwners[newOwner].push(msg.sender);
        emit proposedOwner(newOwner, msg.sender);
    }


    function SignProposedOwner(address newOwner) onlyOwner public {

        if (hasSignedOwnerProposal(newOwner, msg.sender)) {
            revert AlreadySignedOwnerRequest();
        }

        if(s_proposedOwners[newOwner].length == s_owners.length - 1) {
            // Add the new owner
            s_owners.push(newOwner);
            // Remove the proposed owner from the list
            delete s_proposedOwners[newOwner];
            emit AddedOwner(newOwner);

            return;
        }

        s_proposedOwners[newOwner].push(msg.sender);
        emit SignedOwnerProposal(newOwner, msg.sender);

    }

    function SignProposedTransaction(uint256 index) onlyOwner public {
        if (index >= s_proposals.length) {
            revert InvalidProposalIndex();
        }

        Proposal memory proposal = s_proposals[index];

        if (hasSigned(proposal, msg.sender)) {
            revert AlreadySignedTransactionRequest();
        }

        if(proposal.signatures.length == s_owners.length - 1) {
            // Execute the transaction
            if(proposal.to == address(0)) {
                revert InvalidRecipientAddress();
            }
            if(proposal.value > address(this).balance) {
                revert insufficientFunds();
            }

            (bool success, ) = payable(proposal.to).call{value: proposal.value}("");
            require(success, "Transaction failed");

            // Remove the proposal from the list
            s_proposals[index] = s_proposals[s_proposals.length - 1];
            s_proposals.pop();
            emit TransactionExecuted(proposal.to, proposal.value);
            return;
        }else{
        s_proposals[index].signatures.push(msg.sender);
        emit SignedTransactionProposal(s_proposals[index].to, s_proposals[index].value, msg.sender);
        }
    }

    function RejectProposedTransaction(uint256 index) onlyOwner public {
        if (index >= s_proposals.length) {
            revert InvalidProposalIndex();
        }
        // Remove the proposal from the list
        address recipient = s_proposals[index].to;
        uint256 value = s_proposals[index].value;
        s_proposals[index] = s_proposals[s_proposals.length - 1];
        s_proposals.pop();
        emit DeclinedTransactionProposal(recipient, value, msg.sender);
    }

    function RejectProposedOwner(address newOwner) onlyOwner public {
        if (!AlreadyProposed(newOwner)) {
            revert InvalidProposalIndex();
        }
        // Remove the proposed owner from the list
        delete s_proposedOwners[newOwner];
        emit DeclinedOwnerProposal(newOwner, msg.sender);
    }
    
    // HELPERS

    function hasOwner(address owner) private view returns (bool) {
        address[] memory m_owners = s_owners;
        for (uint256 i = 0; i < m_owners.length; i++) {
            if (m_owners[i] == owner) {
                return true;
            }
        }
        return false;
    }

    function AlreadyProposed(address owner) private view returns (bool) {
        return s_proposedOwners[owner].length > 0;
    }

    function hasSigned(Proposal memory proposal, address signer) private pure returns (bool) {
        for (uint256 i = 0; i < proposal.signatures.length; i++) {
            if (proposal.signatures[i] == signer) {
                return true;
            }
        }
        return false;
    }

    function hasSignedOwnerProposal(address newOwner, address signer) private view returns (bool) {
        address[] memory signatures = s_proposedOwners[newOwner];
        for (uint256 i = 0; i < signatures.length; i++) {
            if (signatures[i] == signer) {
                return true;
            }
        }
        return false;
    }

    // GETTERS

    function getProposaedTransactions() public view returns (Proposal[] memory) {
        return s_proposals;
    }

    function getProposedOwnerSignatures(address newOwner) private view returns (address[] memory) {
        return s_proposedOwners[newOwner];
    }

    function getOwners() public view returns (address[] memory) {
        return s_owners;
    }
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // MODIFIERS

    modifier onlyOwner() {
        if (hasOwner(msg.sender) == false) {
            revert NotOwner();
        }
        _;
    }


}
