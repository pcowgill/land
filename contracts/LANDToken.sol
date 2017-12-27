pragma solidity ^0.4.15;

import 'zeppelin-solidity/contracts/ownership/Ownable.sol';
import './NFT/FullNFT.sol';

contract LANDToken is Ownable, FullNFT {

  string public name = 'Decentraland World';
  string public symbol = 'LAND';

  mapping (address => uint) public latestPing;

  event Ping(address user);

  function assignNewParcel(
    address beneficiary,
    uint tokenId,
    string _metadata
  ) onlyOwner public {
    require(tokenOwner[tokenId] == 0);
    _assignNewParcel(beneficiary, tokenId, _metadata);
  }

  function _assignNewParcel(
    address beneficiary,
    uint tokenId,
    string _metadata
  ) internal {
    _addTokenTo(beneficiary, tokenId);
    totalTokens++;
    _tokenMetadata[tokenId] = _metadata;

    Created(tokenId, beneficiary, _metadata);
  }

  function ping() public {
    latestPing[msg.sender] = now;
    Ping(msg.sender);
  }

  function buildTokenId(uint x, uint y) public constant returns (uint256) {
    uint result = ((x << 128) & (2**128 - 1)) | (y & (2**128));
    return result;
  }

  function exists(uint x, uint y) public constant returns (bool) {
    return ownerOfLand(x, y) != 0;
  }

  function ownerOfLand(uint x, uint y) public constant returns (address) {
    return tokenOwner[buildTokenId(x, y)];
  }

  function transferLand(address to, uint x, uint y) public {
    return transfer(to, buildTokenId(x, y));
  }

  function takeLand(uint x, uint y) public {
    return takeOwnership(buildTokenId(x, y));
  }

  function approveLandTransfer(address to, uint x, uint y) public {
    return approve(to, buildTokenId(x, y));
  }

  function landMetadata(uint x, uint y) constant public returns (string) {
    return _tokenMetadata[buildTokenId(x, y)];
  }

  function updateLandMetadata(uint x, uint y, string _metadata) public {
    return updateTokenMetadata(buildTokenId(x, y), _metadata);
  }

  function updateManyLandMetadata(uint[] x, uint[] y, string _metadata) public {
    for (uint i = 0; i < x.length; i++) {
      updateTokenMetadata(buildTokenId(x[i], y[i]), _metadata);
    }
  }

  function dropLostLand(address owner, uint[] tokens) onlyOwner public {
    require(now - latestPing[owner] > 1 years);
    for (uint i = 0; i < tokens.length; i++) {
      require(ownerOf(tokens[i]) == owner);
      _transfer(owner, 0, tokenId);
      Transfer(owner, 0, tokenId);
    }
  }
}
