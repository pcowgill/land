pragma solidity ^0.4.18;

import './MetadataHolder.sol';

contract MetadataHolderBase is MetadataHolder {

  bytes4 public GET_METADATA = bytes4(keccak256("getMetadata(uint256)"));
  bytes4 public ERC165Interface = bytes4(keccak256("supportsInterface(bytes4)"));

  function supportsInterface(bytes4 interfaceId) external view returns (bool) {
    if (interfaceId == 0xffffffff) {
      return false;
    }
    if (interfaceId == ERC165Interface) {
      return true;
    }
    if (interfaceId == GET_METADATA) {
      return true;
    }
    return false;
  }

  function getMetadata(uint256 /* assetId */) external view returns (bytes32) {
    return 0;
  }
}
