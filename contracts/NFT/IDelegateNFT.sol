pragma solidity ^0.4.15;

contract IDelegateNFT {

  function delegateOwnership(address beneficiary);

  /**
   * Event triggered when delegation happens
   */
  event Delegation(
    address owner,
    address beneficiary
  );
}
