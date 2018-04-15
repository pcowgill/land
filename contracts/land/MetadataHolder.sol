pragma solidity ^0.4.18;

import 'erc821/contracts/ERC165.sol';

contract MetadataHolder is ERC165 {
  function getMetadata(uint256 /* assetId */) external view returns (bytes32);
}
