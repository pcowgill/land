pragma solidity ^0.4.15;

import './MetadataNFT.sol';
import './IDelegateNFT.sol';

contract DelegateNFT is MetadataNFT, IDelegateNFT {

  /**
   * Allows an external account full control over transfers and metadata of the tokens owned
   */
  mapping(address => address) public delegate;

  /**
   * Decorator for functions that should be allowed only for the owner of a token
   */
  modifier isOwnerOf(address sender, uint tokenId) private {
    require(tokenOwner[tokenId] != 0
      && (   sender == tokenOwner[tokenId]
          || sender == delegate[owner]
         )
    );
    _;
  }

  /**
   * Decorator for functions reserved for accounts that can transfer a token
   */
  modifier canTransfer(address sender, uint tokenId) private {
    address owner = tokenOwner[tokenId]
    require(tokenOwner[tokenId] != 0
      && (   sender == owner
          || sender == delegate[owner]
          || sender == allowedTransfer[tokenId]
         )
    );
    _;
  }

  /**
   * Decorator for functions reserved for accounts that can modify a token's metadata
   */
  modifier canModify(address sender, uint tokenId) private {
    address owner = tokenOwner[tokenId]
    require(owner != 0
      && (   sender == owner
          || sender == delegate[owner]
          || sender == allowedMetadataModification[tokenId]
         )
    );
    _;
  }

  function delegateOwnership(address beneficiary)
    public
  {
    delegate[msg.sender] = beneficiary;
    Delegation(msg.sender, beneficiary);
  }
}

