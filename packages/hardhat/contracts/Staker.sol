// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

  ExampleExternalContract public exampleExternalContract;

  mapping ( address => uint256 ) public balances;

  uint256 public constant threshold = 1 ether;
  uint256 public deadline = block.timestamp + 72 hours;
  bool public openForWithdraw;

  event Stake(address, uint256);

  error DeadlineNotMet();
  error UserBalanceIsZero();

  constructor(address exampleExternalContractAddress) public {
    exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
  function stake() public payable {
    balances[msg.sender] += msg.value;

    emit Stake(msg.sender, msg.value);
  }

  // After some `deadline` allow anyone to call an `execute()` function
  //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
  // if the `threshold` was not met, allow everyone to call a `withdraw()` function
  function execute() public {
    
    if(block.timestamp > deadline) {
      uint256 balance = address(this).balance;
      
      if(balance > threshold) {
        exampleExternalContract.complete{value: balance}();
      } else {
        openForWithdraw = true;
      }
    } else {
      revert DeadlineNotMet();
    }
  }

  // Add a `withdraw()` function to let users withdraw their balance
  function withdraw() public {
    uint256 userBalance = balances[msg.sender];

    if(userBalance == 0) {
      revert UserBalanceIsZero();
    }
    
    balances[msg.sender] = 0;

    payable(msg.sender).transfer(userBalance);
  }

  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  function timeLeft() public view returns(uint256) {
    if(block.timestamp >= deadline) {
      return 0;
    }

    return deadline - block.timestamp;
  }

  // Add the `receive()` special function that receives eth and calls stake()
  receive() payable external {
    stake();
  }
  
}
