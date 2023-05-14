// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract MultiSig {
    address[] public owners;
    uint public required;
    mapping(uint => mapping(address => bool)) public confirmations;
    uint public confirmation = 0;

    mapping(uint => Transaction) public transactions;
    uint public transactionCount = 0;

    struct Transaction{
        address destination;
        uint256 value;
        bool executed;
        bytes data;
    }


    constructor(address[] memory _owners, uint _confirmation){
        require(_owners.length > 0);
        owners = _owners;
        require(_confirmation > 0 && (_confirmation < _owners.length));
        required = _confirmation;
    } 

    function addTransaction(address _destination, uint256 _value,bytes memory _data) internal returns(uint256) {
        uint txId = transactionCount;
        transactions[txId] = Transaction(_destination,_value,false,_data);
        transactionCount++;        
        return txId;
    }

    function confirmTransaction(uint _idx) public {
        bool isOwner;
        for(uint i=0; i<owners.length; i++){
            if(msg.sender == owners[i]){
                isOwner = true;
                break;
            }
        }
        require(isOwner,"only  can confirm tx");
            confirmations[_idx][msg.sender] = true;

        if(getConfirmationsCount(_idx) >= required){
            executeTransaction(_idx);
        }
    } 

    function getConfirmationsCount(uint transactionId) public view returns(uint256){
        uint256 count = 0;
        for(uint256 i=0; i<owners.length; i++){
            if(confirmations[transactionId][owners[i]]){
                count++;
            }
        }
        return count;
    }

    function submitTransaction(address _destination, uint _value,bytes memory _data) external {
        uint idx = addTransaction(_destination, _value,_data);
        confirmTransaction(idx);
    }

    function isConfirmed(uint _idx) public view returns(bool){
        require(_idx < transactionCount);

        uint txCount = getConfirmationsCount(_idx);
        if(txCount >= required){
            return true;
        }
        return false;
    }

    function executeTransaction(uint _idx) public {
        require(isConfirmed(_idx));
        uint amount = transactions[_idx].value;
        (bool success, ) = transactions[_idx].destination.call{value:amount}(transactions[_idx].data);
        require(success,"tx failed");
        transactions[_idx].executed = true;
    } 

    receive() external payable {}

}
