//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;


/**
 * This Smart Contract implements a Multisig Wallet.
 * Any user can deposit money from his account.
 * But withdrawls require n-of-N approvals to go through.
 */
contract MultisigWallet {

    /** owners of the wallet*/
    mapping (address => bool) private ownersMap;
    address[] private ownersList;

    uint private numberOfRequiredApprovals;

    /** 
    * transferRequests[recipientAddress][amount][ownerAddress] = true if owner has approved transaction,
    *                                                         = false, otherwise.
    */
    mapping (address => mapping (uint => mapping (address => bool))) private transferRequests;

    /** Wallet´s balance */
    uint private balance;

    modifier onlyOwner {
        require ( isOwner(msg.sender) );
        _;
    }

    /**
    * Remix deployment syntax: 
    *    ["<address_0>","<address_1>",...,"<address_n>"], <uint>
    * 
    *  For example:
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

    function approveTransferRequest(address recipient, uint amount) external onlyOwner {
        transferRequests[recipient][amount][msg.sender]=true;
        if (haveEnoughApprovals(recipient, amount)){
            transfer( payable(recipient), amount);
        }
    }

    function haveEnoughApprovals (address recipient, uint amount) private view returns (bool) {
        uint approvals = 0;
        for (uint i = 0; i < ownersList.length; i++) {
            if (transferRequests[recipient][amount][ownersList[i]] == true) {
                approvals++;
            }
        }
        return (approvals >= numberOfRequiredApprovals);
    }

    function deposit () external payable onlyOwner {
        require (balance + msg.value > balance);
        balance+=msg.value;
    }

    function transfer (address payable recipient, uint amount) private {
        require(balance >= amount);
        require(balance - amount < balance);
        balance-=amount;
        recipient.transfer(amount);
    }


    function isOwner (address _address) private view returns (bool)  {
        return ownersMap[_address];
    }

    function addOwner(address _address) private {
        if(ownersMap[_address] == false) {
            ownersList.push(_address);
            ownersMap[_address] = true;
        }
    }


}
