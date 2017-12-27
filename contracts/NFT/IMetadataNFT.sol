pragma solidity ^0.4.15;

contract IMetadataNFT {
  function allowModifications(address beneficiary, uint tokenId) public constant;
  function tokenMetadata(uint tokenId) public returns (string);
  function metadata(uint tokenId) public returns (string);
  function updateTokenMetadata(uint tokenId, string _metadata) public returns;

  event UpdateApproval(
    address owner,
    address beneficiary,
    uint tokenId
  );
  event MetadataUpdate(
    uint tokenId,
    address tokenOwner,
    address updatingAccount,
    string metadata
  );
}

