pragma solidity ^0.4.18;

import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import 'zeppelin-solidity/contracts/ownership/Ownable.sol';

import 'erc821/contracts/IERC721Base.sol';
import 'erc821/contracts/ERC721Holder.sol';

contract PingableDAR is IERC721Base {
  function ping() public;
}

contract EstateOwner is ERC721Holder, Ownable {
  using SafeMath for uint256;

  PingableDAR public dar;

  string public data;
  address public operator;

  uint256[] tokenIds;
  uint256[] index;

  function EstateOwner(
    address _dar
  ) public {
    require(_dar != 0);
    dar = PingableDAR(dar);
  }

  // onERC721Received: Count
  function onERC721Received(
    address oldOwner,
    uint256 tokenId,
    string // unused
  )
    public
    returns (bytes4)
  {
    require(msg.sender == address(dar));

    /**
     * tokenId is a list of owned tokens
     */
    tokenIds.push(tokenId);

    /**
     * index is the position (1-based) of the token in the array
     */
    index[tokenId] = tokenIds.length;

    return super.onERC721Received(oldOwner, tokenId, "");
  }

  function detectReceived(uint256 tokenId) {
    require(tokenIds[tokenId] == 0);
    require(dar.ownerOf(tokenId) == this);

    tokenIds.push(tokenId);
    index[tokenId] = tokenIds.length;
  }

  function send(
    uint256 tokenId,
    address destinatory
  )
    public
    onlyOwner
  {
    /**
     * Using 1-based indexing to be able to make this check
     */
    require(index[tokenId] != 0);

    uint lastIndex = tokenIds.length - 1;

    /**
     * Get the index of this token in the tokenIds list
     */
    uint indexInArray = index[tokenId] - 1;

    /**
     * Get the tokenId at the end of the tokenIds list
     */
    uint tempTokenId = tokenIds[lastIndex];

    /**
     * Store the last token in the position previously occupied by tokenId
     */
    index[tempTokenId] = indexInArray + 1;
    tokenIds[indexInArray] = tempTokenId;
    tokenIds.length = lastIndex;

    /**
     * Drop this tokenId from both the index and tokenId list
     */
    index[tokenId] = 0;
    delete tokenIds[lastIndex];

    dar.safeTransferFrom(this, destinatory, tokenId);
  }

  function transferMany(
    uint256[] tokens,
    address destinatory
  ) {
    uint length = tokens.length;
    for (uint i = 0; i < length; i++) {
      send(tokens[i], destinatory);
    }
  }

  function size() public view returns (uint256) {
    return tokenIds.length;
  }

  function updateMetadata(
    string _data
  )
    public
    onlyUpdateAuthorized
  {
    data = _data;
  }

  function getMetadata()
    view
    public
    returns (string)
  {
    return data;
  }

  // updateMetadata

  modifier onlyUpdateAuthorized() {
    require(isUpdateAuthorized(msg.sender));
    _;
  }

  function setUpdateOperator(
    address _operator
  )
    public
    onlyOwner
  {
    operator = _operator;
  }

  function isUpdateAuthorized(
    address _operator
  )
    public
    view
    returns (bool)
  {
    return owner == _operator || operator == _operator;
  }

  function ping() public {
    dar.ping();
  }
}
