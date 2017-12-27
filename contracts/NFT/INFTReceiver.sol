pragma solidity ^0.4.15;

contract INFTReceiver {
  function receiveToken(address, uint256, bytes) public returns (bool);
}
