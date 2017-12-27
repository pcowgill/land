pragma solidity ^0.4.15;

import './DelegateNFT.sol';

contract FullNFT is DelegateNFT {

  /**
   * Global lock that prevents reentrancy when using `transfer` to a contract
   */
  uint8 reentrancyLock;
  uint8 MAX_REENTRANCY = 2;

  /**
   * Transfer a token to a new owner.
   * See `transfer(to, tokenId, data, method)` for more information.
   *
   */
  function transfer(address to, uint tokenId)
    canTransfer(msg.sender, tokenId)
    public
  {
    return transfer(to, tokenId, '', '');
  }

  /**
   * Transfer a token to a new owner.
   *
   * This clears the values for `allowedTransfer` and `allowedMetadataModification`.
   *
   * Note that the EIP 721 requires the use of `transferFrom` if msg.sender is not the owner
   * Given that this is done to mimick ERC20 functionality, we relax this requirement at the cost of
   * not being fully compliant. Please follow the discussion at https://github.com/ethereum/EIPs/issues/721
   *
   * If the target account is a contract, then the method
   * `receiveToken(address, uint256, bytes)` is called with the current owner's address,
   * the id of the token received, and the `data` argument.
   */
  function transfer(address to, uint tokenId, bytes data, string method)
    canTransfer(msg.sender, tokenId)
    public
  {
    address owner = tokenOwner[tokenId];
    _transfer(owner, to, tokenId);

    if (isContract(to)) {
      if (method == '') {
        method = "receiveToken(address, uint256, bytes)";
      }
      require(reentrancyLock < MAX_REENTRANCY);
      reentrancyLock++;
      assert(to.call.value(0)(bytes4(sha3(method)), owner, tokenId, data));
      reentrancyLock--;
    }
    Transfer(owner, to, tokenId);

    return true;
  }

  function isContract(address _addr) private returns (bool) {
    uint length;
    assembly {
      length := extcodesize(_addr)
    }
    return length > 0;
  }
}

