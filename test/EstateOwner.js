import assertRevert from './helpers/assertRevert'
import { increaseTimeTo, duration, latestTime } from './helpers/increaseTime'

const BigNumber = web3.BigNumber

const Estate = artifacts.require('EstateOwner')
const LANDRegistry = artifacts.require('LANDRegistryTest')
const LANDProxy = artifacts.require('LANDProxy')

const NONE = '0x0000000000000000000000000000000000000000'

require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should()

contract('LANDRegistry', accounts => {
  const [creator, user] = accounts

  let registry = null,
    proxy = null
  let land = null

  const _name = 'Decentraland LAND'
  const _symbol = 'LAND'

  const sentByUser = { from: user }
  const sentByCreator = { from: creator }
})
