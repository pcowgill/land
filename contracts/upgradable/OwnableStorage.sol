pragma solidity ^0.4.18;

contract OwnableStorage {

  address public owner;

  constructor() internal {
    owner = msg.sender;
  }

}
