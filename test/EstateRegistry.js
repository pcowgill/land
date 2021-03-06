import assertRevert from './helpers/assertRevert'
import setupContracts, {
  ESTATE_NAME,
  ESTATE_SYMBOL
} from './helpers/setupContracts'
import createEstateFull from './helpers/createEstateFull'

const BigNumber = web3.BigNumber

const LANDProxy = artifacts.require('LANDProxy')

const EMPTY_ADDRESS = '0x0000000000000000000000000000000000000000'

require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should()

/**
 * Important:
 *   The LAND registry uses an encoded version of the coordinates as the tokenId which you can find on LANDRegistry#encodeTokenId but
 *   you'll see that this file uses tokenIds like `1`, `2`, etc.
 *   This is because encoding a pair like `(0, 1)` returns `1`, `(0, 2)` returns `2`, and so on.
 */
contract('EstateRegistry', accounts => {
  const [creator, user, anotherUser, yetAnotherUser, hacker] = accounts

  let contracts = null
  let registry = null
  let proxy = null
  let land = null
  let estate = null

  const creationParams = {
    gas: 7e6,
    gasPrice: 1e9,
    from: creator
  }
  const sentByUser = { ...creationParams, from: user }
  const sentByAnotherUser = { ...creationParams, from: anotherUser }
  const sentByCreator = { ...creationParams, from: creator }

  const fiveX = [0, 0, 0, 0, 0]
  const fiveY = [1, 2, 3, 4, 5]

  const newMetadata = 'new land content'

  async function createEstateMetadata(xs, ys, owner, metadata, sendParams) {
    return createEstateFull(contracts, xs, ys, owner, metadata, sendParams)
  }

  async function createEstate(xs, ys, owner, sendParams) {
    return createEstateFull(contracts, xs, ys, owner, '', sendParams)
  }

  async function createTwoEstates(owner, sendParams) {
    await land.assignMultipleParcels([0, 0], [1, 2], owner, sentByCreator)
    await createEstate([0], [1], owner, sendParams)
    await createEstate([0], [2], owner, sendParams)

    let estateIds = await Promise.all([
      estate.tokenOfOwnerByIndex(owner, 0),
      estate.tokenOfOwnerByIndex(owner, 1)
    ])

    return estateIds.map(id => id.toNumber())
  }

  async function createUserEstateWithToken1() {
    await land.assignMultipleParcels([0], [1], user, sentByCreator)
    return createEstate([0], [1], user, sentByUser)
  }

  async function createUserEstateWithNumberedTokens() {
    await land.assignMultipleParcels(fiveX, fiveY, user, sentByCreator)
    return createEstate(fiveX, fiveY, user, sentByUser)
  }

  async function assertEstateCount(owner, expectedCount) {
    const tokenCount = await estate.balanceOf.call(owner)
    tokenCount.toNumber().should.be.equal(expectedCount)
  }

  async function assertRegistry(requiredRegistry) {
    const registry = await estate.registry.call()
    registry.should.be.equal(requiredRegistry)
  }

  async function assertMetadata(estateId, requiredMetadata) {
    const metadata = await estate.getMetadata.call(estateId)
    metadata.should.be.equal(requiredMetadata)
  }

  async function assertNFTBalance(user, expected) {
    const balance = await land.balanceOf(user)
    balance.toString().should.be.equal(expected.toString())
  }

  async function assertEstateSize(estateId, expected) {
    const balance = await estate.getEstateSize(estateId)
    balance.toString().should.be.equal(expected.toString())
  }

  async function assertNFTOwner(assetId, expectedOwner) {
    const owner = await land.ownerOf(assetId)
    owner.should.be.equal(expectedOwner)
  }

  function transferOut(estateId, index, who) {
    if (!who) {
      who = sentByUser
    }
    return estate.transferLand(estateId, index, anotherUser, who)
  }

  function transferIn(estateId, landId, userAddress = anotherUser) {
    return land.safeTransferFromToEstate(
      userAddress,
      estate.address,
      landId,
      estateId,
      getParams(userAddress)
    )
  }

  function getParams(userAddress) {
    let params = sentByAnotherUser

    if (userAddress === user) {
      params = sentByUser
    } else if (userAddress === creator) {
      params = sentByCreator
    }

    return params
  }

  async function assertLandIdAtIndex(estateId, index, value) {
    const landId = await estate.estateLandIds.call(estateId, index)
    landId.toString().should.be.equal(value.toString())
  }

  function assertEvent(log, expectedEventName, expectedArgs) {
    const { event, args } = log
    event.should.be.eq(expectedEventName)

    for (let key in expectedArgs) {
      let value = args[key]
      if (value instanceof BigNumber) {
        value = value.toString()
      }

      value.should.be.equal(expectedArgs[key], `[assertEvent] ${key}`)
    }
  }

  async function getEstateEvents(eventName) {
    return new Promise((resolve, reject) => {
      estate[eventName]().get(function(err, logs) {
        if (err) reject(new Error(`Error fetching the ${eventName} events`))
        resolve(logs)
      })
    })
  }

  beforeEach(async function() {
    contracts = await setupContracts(creator, creationParams)
    proxy = contracts.proxy
    registry = contracts.registry
    estate = contracts.estate
    land = contracts.land
  })

  describe('name', function() {
    it('has a name', async function() {
      const name = await estate.name()
      name.should.be.equal(ESTATE_NAME)
    })
  })

  describe('symbol', function() {
    it('has a symbol', async function() {
      const symbol = await estate.symbol()
      symbol.should.be.equal(ESTATE_SYMBOL)
    })
  })

  describe('set Land Registry', function() {
    it('set works correctly', async function() {
      const registry = await LANDProxy.new(creationParams)
      await estate.setLANDRegistry(registry.address, creationParams)
      await assertRegistry(registry.address)
    })

    it('should throw if setting a non-contract', async function() {
      await assertRevert(estate.setLANDRegistry(hacker, creationParams))
    })

    it('unauthorized user can not set registry', async function() {
      const registry = await LANDProxy.new(creationParams)
      await assertRevert(
        estate.setLANDRegistry(registry.address, sentByAnotherUser)
      )
    })
  })

  describe('create Estate', function() {
    it('the registry can create estates', async function() {
      await createTwoEstates(user, sentByUser)
      await assertEstateCount(user, 2)
    })

    it('only the registry can create estates', async function() {
      await assertRevert(estate.mint(user))
    })

    it('supports setting the metadata on create', async function() {
      await land.assignMultipleParcels([0], [1], user, sentByCreator)

      const metadata = 'name,description'
      const estateId = await createEstateMetadata(
        [0],
        [1],
        user,
        metadata,
        sentByUser
      )
      await assertMetadata(estateId, metadata)
    })

    it('should emit the CreateEstate event on mint', async function() {
      await land.assignMultipleParcels([0], [1], user, sentByCreator)

      const metadata = 'name,description'
      const { logs } = await estate.mintEstate(user, metadata)

      logs.length.should.be.equal(2)

      // ERC721
      assertEvent(logs[0], 'Transfer', {
        _from: EMPTY_ADDRESS,
        _to: user,
        _tokenId: '1'
      })

      // Estate
      assertEvent(logs[1], 'CreateEstate', {
        owner: user,
        estateId: '1',
        data: metadata
      })
    })
  })

  describe('transfer many Estates', function() {
    it('the owner can transfer many estates', async function() {
      const estateIds = await createTwoEstates(user, sentByUser)

      await estate.safeTransferManyFrom(
        user,
        anotherUser,
        estateIds,
        sentByUser
      )

      await assertEstateCount(user, 0)
      await assertEstateCount(anotherUser, 2)
    })

    it('only the owner can transfer many estates', async function() {
      const estateIds = await createTwoEstates(user, sentByUser)
      await assertRevert(
        estate.safeTransferManyFrom(
          user,
          anotherUser,
          estateIds,
          sentByAnotherUser
        )
      )
    })
  })

  describe('update metadata and update operator', function() {
    it('update works correctly', async function() {
      const estateId = await createUserEstateWithToken1()
      await estate.updateMetadata(estateId, newMetadata, sentByUser)
      await assertMetadata(estateId, newMetadata)
    })

    it('unauthorized user can not update', async function() {
      const estateId = await createUserEstateWithToken1()
      await assertRevert(
        estate.updateMetadata(estateId, newMetadata, sentByAnotherUser)
      )
    })

    it('unauthorized user can not set update operator', async function() {
      const estateId = await createUserEstateWithToken1()
      await assertRevert(
        estate.setUpdateOperator(estateId, yetAnotherUser, sentByAnotherUser)
      )
    })

    it('update operator can not transfer tokens out', async function() {
      const estateId = await createUserEstateWithToken1()
      await estate.setUpdateOperator(estateId, anotherUser, sentByUser)
      await assertRevert(
        estate.transferLand(estateId, 1, yetAnotherUser, sentByAnotherUser)
      )
    })
  })

  describe('transfer tokens', function() {
    it('owner can transfer tokens in', async function() {
      const estateId = await createUserEstateWithToken1()
      await land.assignMultipleParcels([0], [2], user, sentByCreator)
      await transferIn(estateId, 2, user)
      await assertEstateSize(estateId, 2)
    })

    it('transfering tokens in fires the AddLand event', async function() {
      const landId = '2'
      const estateId = await createUserEstateWithToken1()
      await land.assignMultipleParcels([0], [2], user, sentByCreator)

      let logs = await getEstateEvents('AddLand')
      logs.length.should.be.equal(0)

      await transferIn(estateId, 2, user)
      logs = await getEstateEvents('AddLand')

      logs.length.should.be.equal(1)
      assertEvent(logs[0], 'AddLand', { estateId, landId })
    })

    it('user cannot transfer tokens to an undefined estate', async function() {
      const estateId = '1'
      await land.assignMultipleParcels([0], [2], user, sentByCreator)
      await assertRevert(transferIn(estateId, 2, user))
    })

    it('random user can transfer tokens in', async function() {
      const estateId = await createUserEstateWithToken1()
      await land.assignMultipleParcels([0], [2], anotherUser, sentByCreator)
      await transferIn(estateId, 2, anotherUser)
      await assertEstateSize(estateId, 2)
    })

    it('owner can transfer tokens out', async function() {
      const estateId = await createUserEstateWithToken1()
      await estate.transferLand(estateId, 1, anotherUser, sentByUser)
      await assertEstateSize(estateId, 0)
      await assertNFTOwner(1, anotherUser)
    })

    it('random user can not transfer tokens out', async function() {
      const estateId = await createUserEstateWithToken1()
      await assertRevert(
        estate.transferLand(estateId, 1, hacker, sentByAnotherUser)
      )
    })

    it('random user can not transfer many tokens out', async function() {
      const estateId = await createUserEstateWithToken1()
      await assertRevert(
        estate.transferManyLands(estateId, [1], hacker, sentByAnotherUser)
      )
    })

    it('owner can not transfer tokens out to the empty address', async function() {
      const estateId = await createUserEstateWithToken1()
      await assertRevert(
        estate.transferLand(estateId, 1, EMPTY_ADDRESS, sentByUser)
      )
    })

    it('transfering tokens out should emit the RemoveLand event', async function() {
      const landId = '1'
      const estateId = await createUserEstateWithToken1()
      const { logs } = await estate.transferLand(
        estateId,
        landId,
        anotherUser,
        sentByUser
      )

      logs.length.should.be.equal(1)

      assertEvent(logs[0], 'RemoveLand', {
        estateId,
        landId,
        destinatary: anotherUser
      })
    })

    it('owner can transfer many tokens out', async function() {
      const estateId = await createUserEstateWithNumberedTokens()
      await estate.transferManyLands(
        estateId,
        [1, 2, 3],
        anotherUser,
        sentByUser
      )
      await assertEstateSize(estateId, 2)
    })
  })

  describe('operator transfering tokens', function() {
    it('operator can transfer tokens out', async function() {
      const estateId = await createUserEstateWithToken1()
      await estate.setApprovalForAll(anotherUser, true, sentByUser)
      await transferOut(estateId, 1, sentByAnotherUser)
    })

    it('operator can transfer many tokens out', async function() {
      const estateId = await createUserEstateWithToken1()
      await estate.setApprovalForAll(anotherUser, true, sentByUser)
      await estate.transferManyLands(
        estateId,
        [1],
        anotherUser,
        sentByAnotherUser
      )
    })

    it('operator can not transfer tokens out after deauth', async function() {
      const estateId = await createUserEstateWithToken1()
      await estate.setApprovalForAll(anotherUser, true, sentByUser)
      await transferOut(estateId, 1, sentByAnotherUser)
      await transferIn(estateId, 1)
      await estate.setApprovalForAll(anotherUser, false, sentByUser)
      await assertRevert(transferOut(estateId, 1, sentByAnotherUser))
    })

    it('operator can not transfer many tokens out after deauth', async function() {
      const estateId = await createUserEstateWithToken1()
      await estate.setApprovalForAll(anotherUser, true, sentByUser)
      await transferOut(estateId, 1, sentByAnotherUser)
      await transferIn(estateId, 1)
      await estate.setApprovalForAll(anotherUser, false, sentByUser)
      await assertRevert(
        estate.transferManyLands(estateId, [1], anotherUser, sentByAnotherUser)
      )
    })
  })

  describe('order of tokens is correctly accounted', function() {
    it('five in, middle out, one in, middle out', async function() {
      const estateId = await createUserEstateWithNumberedTokens()
      await assertNFTBalance(estate.address, 5)
      await transferOut(estateId, 2)
      await assertLandIdAtIndex(estateId, 1, 5)
      await transferIn(estateId, 2)
      await assertLandIdAtIndex(estateId, 4, 2)
      await transferOut(estateId, 3)
      await assertLandIdAtIndex(estateId, 2, 2)
    })

    it('five in, empty, refill', async function() {
      const estateId = await createUserEstateWithNumberedTokens()
      await transferOut(estateId, 2)
      await transferOut(estateId, 1)
      await transferOut(estateId, 3)
      await transferOut(estateId, 4)
      await transferOut(estateId, 5)
      await assertNFTBalance(estate.address, 0)
      await transferIn(estateId, 2)
      await transferIn(estateId, 1)
      await transferIn(estateId, 3)
      await transferIn(estateId, 4)
      await transferIn(estateId, 5)
      await assertNFTBalance(estate.address, 5)
      await assertLandIdAtIndex(estateId, 0, 2)
      await assertLandIdAtIndex(estateId, 1, 1)
      await assertLandIdAtIndex(estateId, 2, 3)
      await assertLandIdAtIndex(estateId, 3, 4)
      await assertLandIdAtIndex(estateId, 4, 5)
    })
  })
})
