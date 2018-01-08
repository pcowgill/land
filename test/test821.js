/**
 * Ported over from zeppelin-solidity tests for NonFungibleland.sol
 *
 * Given that the test is mostly for common functionality, it should work mostly as-is.
 *
 * Deleted functionality: `burn`
 */
import assertRevert from './helpers/assertRevert';
const BigNumber = web3.BigNumber;

const LANDRegistry = artifacts.require('LANDRegistry');
const LANDProxy = artifacts.require('LANDProxy');

const NONE = '0x0000000000000000000000000000000000000000';

function checkTransferLog(log, parcelId, from, to) {
  log.event.should.be.eq('Transfer');
  log.args.parcelId.should.be.bignumber.equal(parcelId);
  log.args.from.should.be.equal(from);
  log.args.to.should.be.equal(to);
}

function checkApproveLog(log, parcelId, from, to) {
  log.event.should.be.eq('Approve');
  log.args.parcelId.should.be.bignumber.equal(parcelId);
  log.args.owner.should.be.equal(from);
  log.args.beneficiary.should.be.equal(to);
}

require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should();

contract('LANDRegistry', (accounts) => {
  const [creator, user, anotherUser, operator, mallory] = accounts
  let registry = null, proxy = null;
  let land = null;
  const _name = 'LAND Registry';
  const _symbol = 'LAND Test';
  const _firstparcelId = 1;
  const _secondparcelId = 2;
  const _unknownparcelId = 3;

  beforeEach(async function () {
    proxy = await LANDProxy.new({ gas: 4e7, gasPrice: 21e9, from: creator })
    registry = await LANDRegistry.new({ gas: 6e7, gasPrice: 21e9, from: creator })
    await proxy.upgrade(registry.address, '', { from: creator })
    land = await LANDRegistry.at(proxy.address)
    registry = await LANDRegistry.at(registry.address)
  });

  describe('name', function () {
    it('has a name', async function () {
      const name = await land.name();
      name.should.be.equal(_name);
    });
  });


});
