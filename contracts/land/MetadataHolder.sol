pragma solidity ^0.4.22;

import 'erc821/contracts/ERC165.sol';

contract MetadataHolder is ERC165 {
  function getMetadata(uint256 /* assetId */) external view returns (string);
}
