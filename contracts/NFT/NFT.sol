pragma solidity ^0.4.15;

contract NFT {
  function totalSupply() constant returns (uint);
  function balanceOf(address) constant returns (uint);

  function tokenOfOwnerByIndex(address owner, uint index) constant returns (uint);
  function ownerOf(uint tokenId) constant returns (address);

  function transfer(address to, uint tokenId);
  function takeOwnership(uint tokenId);
  function transferFrom(address from, address to, uint tokenId);
  function approve(address beneficiary, uint tokenId);
}

contract NFTEvents {
  event Transfer(address from, address to, uint tokenId);
  event Approval(address owner, address beneficiary, uint tokenId);
}

