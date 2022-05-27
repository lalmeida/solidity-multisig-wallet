//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/**
 * This Smart Contract implements a Multisig Wallet.
 * Any user can deposit money from his account.
 * But withdrawls require n-of-N approvals to go through.
 * 
 * Todo: Remove redundancy from Balance 
 */
contract MultisigWallet {

    event TransferExecuted (address recipient,uint amount);

    event TransferApproved (address recipient,uint amount, address approver);

    /** owners of the wallet*/
    address[] private ownersList;

    uint private numberOfRequiredApprovals;

    /** 
    * transferRequests[recipientAddress][amount][approverAddress] = true if approverAddress has approved transaction,
    *                                                             = false, otherwise.
    */
    mapping (address => mapping (uint => mapping (address => bool))) private transferRequests;

    /** Wallet´s balance */
    uint private balance;

    modifier onlyOwner {
        require ( isOwner(msg.sender), "Only the owners of the wallet can perform this operation." );
        _;
    }

    /**
    * Constructor.
    * 
    * Where:
    *    param _otherOwners: owners of this wallet (other than the msg.sender).
    *    param _numberOfRequiredApprovals: number of approvals required to spend (transfer) wallet´s funds. 
    * 
    * Remix deployment syntax: 
    *    ["<address_0>","<address_1>",...,"<address_n>"], <uint>
    * 
    * For example:
    *    ["0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2","0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db"] , 2
    *
    */
    constructor (address[] memory _otherOwners, uint _numberOfRequiredApprovals) {
        require(_numberOfRequiredApprovals <= _otherOwners.length + 1);

        numberOfRequiredApprovals = _numberOfRequiredApprovals;
        
        addOwner(msg.sender);
        for (uint i=0 ; i < _otherOwners.length; i++) {
            addOwner(_otherOwners[i]);    
        }

    }

    /**
    * Remix input (example):
    * 0xdD870fA1b7C4700F2BD7f44238821C26f7392148,1000000000000000010
    */
    function approveTransferRequest(address recipient, uint amount) external onlyOwner {
        transferRequests[recipient][amount][msg.sender]=true;
        emit TransferApproved(recipient, amount, msg.sender);
        if (haveEnoughApprovals(recipient, amount)){
            clearApprovals(recipient, amount);
            transfer( payable(recipient), amount);
        }
    }

    function haveEnoughApprovals (address recipient, uint amount) public view returns (bool) {
        return (getCurrentNumberOfApprovals(recipient, amount) >= numberOfRequiredApprovals);
    }

    function getCurrentNumberOfApprovals (address recipient, uint amount) public view returns (uint approvals) {
        for (uint i = 0; i < ownersList.length; i++) {
            if (transferRequests[recipient][amount][ownersList[i]] == true) {
                approvals++;
            }
        }
    }

   function clearApprovals (address recipient, uint amount) private {
        for (uint i = 0; i < ownersList.length; i++) {
            transferRequests[recipient][amount][ownersList[i]] = false;
        }
    }

    function deposit () external payable onlyOwner {
        require (balance + msg.value > balance);
        balance+=msg.value;
        assert(balance == address(this).balance);
    }

    function transfer (address payable recipient, uint amount) private {
        require(balance >= amount);
        require(balance - amount < balance);
        assert(balance == address(this).balance);
        balance-=amount;
        recipient.transfer(amount);
        emit TransferExecuted(recipient, amount);
    }

    function getBalance() external view returns (uint) {
        assert(balance == address(this).balance);
        return (balance);
    } 

    
    function isOwner (address _address) private view returns (bool)  {
        /** this array iteration can be avoided if we use an aditional mapping */
        for (uint i = 0; i< ownersList.length; i++) {
            if (ownersList[i] == _address) {
                return true;
            }
        }
        return false;
    }

    function addOwner(address _address) private {
        if( !isOwner(_address) ) {
            ownersList.push(_address);
        }
    }

}
