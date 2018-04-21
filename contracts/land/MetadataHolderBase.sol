pragma solidity ^0.4.22;

contract MetadataHolderBase {

  bytes4 public GET_METADATA = bytes4(keccak256("getMetadata(uint256)"));
  bytes4 public ERC165_SUPPORT = bytes4(keccak256("supportsInterface(bytes4)"));

  function supportsInterface(bytes4 interfaceId) external view returns (bool) {
    if (interfaceId == 0xffffffff) {
      return false;
    }
    if (interfaceId == ERC165_SUPPORT) {
      return true;
    }
    if (interfaceId == GET_METADATA) {
      return true;
    }
    return false;
  }
}
