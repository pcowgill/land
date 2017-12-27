pragma solidity ^0.4.15;

import './NFT.sol';

contract BaseNFT is NFT, NFTEvents {

  /**
   * Global count of tokens
   */
  uint public totalTokens;

  /**
   * Array of owned tokens for a user.
   */
  mapping(address => uint[]) public ownedTokens;

  /**
   * Returns the position of a token in the `ownedTokens` array of its owner.
   *
   * For example, if my address is 0x1234...6789, and the `ownedTokens` mapping looks like this:
   *   ownedTokens[0x1234...6789] = ['A', 'B', 'C']
   *
   * Then the following assertions are true:
   *   tokenIndexInOwnerArray['A'] == 0
   *   tokenIndexInOwnerArray['B'] == 1
   *   tokenIndexInOwnerArray['C'] == 2
   */
  mapping(uint => uint) tokenIndexInOwnerArray;

  /**
   * Mapping from token ID to owner.
   */
  mapping(uint => address) public tokenOwner;

  /**
   * Allows an external account to transfer a token.
   * Does not allow modifying the metadata related to the token.
   */
  mapping(uint => address) public allowedTransfer;

  /**
   * Decorator for functions that should be allowed only for the owner of a token
   */
  modifier isOwnerOf(address sender, uint tokenId) private {
    require(tokenOwner[tokenId] != 0 && sender == tokenOwner[tokenId]);
    _;
  }

  /**
   * Decorator for functions reserved for accounts that can transfer a token
   */
  modifier canTransfer(address sender, uint tokenId) private {
    address owner = tokenOwner[tokenId]
    require(tokenOwner[tokenId] != 0
      && (   sender == owner
          || sender == allowedTransfer[tokenId]
         )
    );
    _;
  }

  /**
   * Return the total supply of tokens issued
   */
  function totalSupply() public constant returns (uint) {
    return totalTokens;
  }

  /**
   * Return the total amount of tokens under somebody's control
   */
  function balanceOf(address owner) public constant returns (uint) {
    return ownedTokens[owner].length;
  }

  /**
   * Returns the id of the `n`-th token owned by an account
   */
  function tokenOfOwnerByIndex(address owner, uint index) public constant returns (uint) {
    require(index >= 0 && index < balanceOf(owner));
    return ownedTokens[owner][index];
  }

  /**
   * Returns the ids of all tokens owned by an account
   */
  function getAllTokens(address owner) public constant returns (uint[]) {
    uint size = ownedTokens[owner].length;
    uint[] memory result = new uint[](size);
    for (uint i = 0; i < size; i++) {
      result[i] = ownedTokens[owner][i];
    }
    return result;
  }

  /**
   * Returns who the owner of a token is.
   * Throws in case the token does not exist.
   */
  function ownerOf(uint tokenId) public constant returns (address) {
    address owner = tokenOwner[tokenId];
    require(owner != 0);
    return owner;
  }

  /**
   * Transfer a token to a new owner.
   */
  function transfer(address to, uint tokenId)
    canTransfer(msg.sender, tokenId)
    public
  {
    address owner = tokenOwner[tokenId];
    _transfer(owner, to, tokenId);
    Transfer(owner, to, tokenId);

    return true;
  }

  /**
   * Legacy function for ERC20-like functionality.
   * The specification requires `msg.sender` to be different from the current owner.
   */
  function takeOwnership(uint tokenId)
    canTransfer(msg.sender, tokenId)
    public
  {
    address owner = tokenOwner[tokenId];
    require(owner != msg.sender);
    _transfer(owner, msg.sender, tokenId);
    Transfer(owner, msg.sender, tokenId);
    return true;
  }

  /**
   * Legacy function for ERC20-like functionality.
   * The specification requires `msg.sender` to be different from the current owner.
   */
  function transferFrom(address from, address to, uint tokenId)
    canTransfer(msg.sender, tokenId)
    public
  {
    address owner = tokenOwner[tokenId];
    require(owner == from);
    require(msg.sender != owner);
    _transfer(owner, to, tokenId);
    Transfer(owner, to, tokenId);
    return true;
  }

  function approve(address beneficiary, uint tokenId)
    canTransfer(msg.sender, tokenId)
    public
  {
    allowedTransfer[tokenId] = beneficiary;
    Approval(tokenOwner[tokenId], beneficiary, tokenId);
  }

  function _transfer(address from, address to, uint tokenId)
    internal
  {
    _clearApproval(tokenId);
    _removeTokenFrom(from, tokenId);
    _addTokenTo(to, tokenId);
  }

  function _addTokenTo(address owner, uint tokenId)
    internal
  {
    tokenOwner[tokenId] = owner;
    tokenIndexInOwnerArray[tokenId] = ownedTokens[owner].length;
    ownedTokens[owner].push(tokenId);
  }

  function _removeTokenFrom(address owner, uint tokenId)
    internal
  {
    uint length = ownedTokens[owner].length;
    require(length > 0);

    if (ownedTokens[owner].length == 1) {
      delete ownedTokens[from][0];
      delete ownedTokens[from];
      delete tokenIndexInOwnerArray[tokenId];
      return
    }

    uint last = length - 1;
    uint index = tokenIndexInOwnerArray[tokenId];
    uint swapToken = ownedTokens[owner][last];

    delete tokenIndexInOwnerArray[tokenId];
    delete ownedTokens[from][last];
    tokenIndexInOwnerArray[swapToken] = index;
    ownedTokens[from][index] = swapToken;
    ownedTokens[from].length = last;
  }

  function _clearApproval(uint tokenId)
    internal
  {
    allowedTransfer[tokenId] = 0;
    Approval(tokenOwner[tokenId], 0, tokenId);
  }
}

