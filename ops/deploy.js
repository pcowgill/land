const utils = require('./utils')

const LANDTerraformSale = artifacts.require('../contracts/LANDTerraformSale.sol')

const assert = (condition, message) => {
  if (!condition) {
    throw new Error(message)
  }
}

const run = async () => {
  const filename = '' // example: ops/config.testnet.json
  assert(filename, 'Missing config filename')

  const input = utils.readJSON(filename)

  assert(input.MANATokenAddress, 'Missing MANAToken address')
  assert(input.terraformReserveAddress, 'Missing TerraformReserve address')
  assert(input.returnVestingRegistryAddress, 'Missing ReturnVestingRegistry address')

  console.log(`Deploying contract: LANDTerraformSale`)
  console.log(`  MANAToken: ${input.MANATokenAddress}`)
  console.log(`  TerraformReserve: ${input.terraformReserveAddress}`)
  console.log(`  ReturnVestingRegistry: ${input.returnVestingRegistryAddress}`)

  const sale = await LANDTerraformSale.new(
    input.MANATokenAddress,
    input.terraformReserveAddress,
    input.returnVestingRegistryAddress,
    {gas: 4700000, gasPrice: 10e9}
  )
  console.log(`Deployed contract: ${sale.address}`)
}

const ret = (callback) => {
  run()
    .then(() => callback())
    .catch(console.log)
    .catch(callback)
}

module.exports = ret
