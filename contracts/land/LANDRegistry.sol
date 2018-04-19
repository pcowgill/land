pragma solidity ^0.4.22;

import '../Storage.sol';

import '../upgradable/Ownable.sol';

import '../upgradable/IApplication.sol';

import 'erc821/contracts/FullAssetRegistry.sol';

import './ILANDRegistry.sol';

import './MetadataHolder.sol';

import '../owner/EstateOwner.sol';

contract LANDRegistry is Storage,
  Ownable, FullAssetRegistry,
  ILANDRegistry
{

  bytes4 public GET_METADATA = bytes4(keccak256("getMetadata(uint256)"));

  function initialize(bytes) public {
    _name = 'Decentraland LAND';
    _symbol = 'LAND';
    _description = 'Contract that stores the Decentraland LAND registry';
  }

  modifier onlyProxyOwner() {
    require(msg.sender == proxyOwner, 'this function can only be called by the proxy owner');
    _;
  }

  //
  // LAND Create and destroy
  //

  modifier onlyOwnerOf(uint256 assetId) {
    require(msg.sender == ownerOf(assetId), 'this function can only be called by the owner of the asset');
    _;
  }

  modifier onlyUpdateAuthorized(uint256 tokenId) {
    require(msg.sender == ownerOf(tokenId) || isUpdateAuthorized(msg.sender, tokenId), 'msg.sender is not authorized to update');
    _;
  }

  function isUpdateAuthorized(address operator, uint256 assetId) public view returns (bool) {
    return operator == ownerOf(assetId) || updateOperator[assetId] == operator;
  }

  function authorizeDeploy(address beneficiary) public onlyProxyOwner {
    authorizedDeploy[beneficiary] = true;
  }
  function forbidDeploy(address beneficiary) public onlyProxyOwner {
    authorizedDeploy[beneficiary] = false;
  }

  function assignNewParcel(int x, int y, address beneficiary) public onlyProxyOwner {
    _generate(encodeTokenId(x, y), beneficiary);
  }

  function assignMultipleParcels(int[] x, int[] y, address beneficiary) public onlyProxyOwner {
    for (uint i = 0; i < x.length; i++) {
      _generate(encodeTokenId(x[i], y[i]), beneficiary);
    }
  }

  //
  // Inactive keys after 1 year lose ownership
  //

  function ping() public {
    latestPing[msg.sender] = now;
  }

  function setLatestToNow(address user) public {
    require(msg.sender == proxyOwner || isApprovedForAll(msg.sender, user));
    latestPing[user] = now;
  }

  //
  // LAND Getters
  //

  function encodeTokenId(int x, int y) view public returns (uint) {
    return ((uint(x) * factor) & clearLow) | (uint(y) & clearHigh);
  }

  function decodeTokenId(uint value) view public returns (int, int) {
    uint x = (value & clearLow) >> 128;
    uint y = (value & clearHigh);
    return (expandNegative128BitCast(x), expandNegative128BitCast(y));
  }

  function expandNegative128BitCast(uint value) pure internal returns (int) {
    if (value & (1<<127) != 0) {
      return int(value | clearLow);
    }
    return int(value);
  }

  function exists(int x, int y) view public returns (bool) {
    return exists(encodeTokenId(x, y));
  }

  function ownerOfLand(int x, int y) view public returns (address) {
    return ownerOf(encodeTokenId(x, y));
  }

  function ownerOfLandMany(int[] x, int[] y) view public returns (address[]) {
    require(x.length > 0);
    require(x.length == y.length);

    address[] memory addrs = new address[](x.length);
    for (uint i = 0; i < x.length; i++) {
      addrs[i] = ownerOfLand(x[i], y[i]);
    }

    return addrs;
  }

  function landOf(address owner) public view returns (int[], int[]) {
    uint256 len = _assetsOf[owner].length;
    int[] memory x = new int[](len);
    int[] memory y = new int[](len);

    int assetX;
    int assetY;
    for (uint i = 0; i < len; i++) {
      (assetX, assetY) = decodeTokenId(_assetsOf[owner][i]);
      x[i] = assetX;
      y[i] = assetY;
    }

    return (x, y);
  }

  function tokenMetadata(uint256 assetId) public view returns (string) {
    address _owner = ownerOf(assetId);
    if (_isContract(_owner)) {
      if (ERC165(_owner).supportsInterface(GET_METADATA)) {
        return MetadataHolder(_owner).getMetadata(assetId);
      }
    }
    return _assetData[assetId];
  }

  function landData(int x, int y) public view returns (string) {
    return tokenMetadata(encodeTokenId(x, y));
  }

  //
  // LAND Transfer
  //

  function transferLand(int x, int y, address to) public {
    uint256 tokenId = encodeTokenId(x, y);
    safeTransferFrom(ownerOf(tokenId), to, tokenId);
  }

  function transferManyLand(int[] x, int[] y, address to) public {
    require(x.length > 0);
    require(x.length == y.length);

    for (uint i = 0; i < x.length; i++) {
      uint256 tokenId = encodeTokenId(x[i], y[i]);
      safeTransferFrom(ownerOf(tokenId), to, tokenId);
    }
  }

  function setUpdateOperator(uint256 assetId, address operator) public onlyOwnerOf(assetId) {
    updateOperator[assetId] = operator;
  }

  // 
  // Estate generation
  // 

  function createEstate(int[] x, int[] y, address beneficiary) public returns (address) {
    require(x.length == y.length);

    EstateOwner estate = new EstateOwner(this, beneficiary);

    transferManyLand(x, y, estate);

    return address(estate);
  }

  //
  // LAND Update
  //

  function updateLandData(int x, int y, string data) public onlyUpdateAuthorized (encodeTokenId(x, y)) {
    uint256 assetId = encodeTokenId(x, y);
    _update(assetId, data);

    emit Update(assetId, _holderOf[assetId], msg.sender, data);
  }

  function updateManyLandData(int[] x, int[] y, string data) public {
    require(x.length > 0);
    require(x.length == y.length, 'invalid length (both arrays in updateManyLandData must be of equal length)');
    for (uint i = 0; i < x.length; i++) {
      updateLandData(x[i], y[i], data);
    }
  }

  function _doTransferFrom(
    address from,
    address to,
    uint256 assetId,
    bytes userData,
    address operator,
    bool doCheck
  ) internal {
    updateOperator[assetId] = address(0);
    super._doTransferFrom(from, to, assetId, userData, operator, doCheck);
  }

  function _isContract(address addr) internal view returns (bool) {
    uint size;
    assembly { size := extcodesize(addr) }
    return size > 0;
  }
}
