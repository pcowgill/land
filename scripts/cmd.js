const inquirer = require('inquirer')

function parseCLICoords(coord) {
  if (!coord) throw new Error('You need to supply a coordinate')

  return coord
    .replace('(', '')
    .replace(')', '')
    .split(/\s*,\s*/)
    .map(coord => parseInt(coord.trim(), 10))
}

async function unlockPrimaryAccountPrompt() {
  const response = await inquirer.prompt([
    {
      type: 'password',
      name: 'password',
      message: 'Please input the primary account password'
    }
  ])
  return unlockPrimaryAccount(response.password)
}

function unlockPrimaryAccount(password, timeout = 1000) {
  return web3.personal.unlockAccount(web3.eth.accounts[0], password, timeout)
}

function getContractAt(name, address) {
  const contract = artifacts.require(name)
  return contract.at(address)
}

task('assign-land', 'Assign land to a beneficiary')
  .addPositionalParam('coord', 'Parcel coordinates (x,y)')
  .addPositionalParam('beneficiary', 'Address of the beneficiary')
  .setAction(async ({ coord, beneficiary }) => {
    // TODO: validate params
    const [x, y] = parseCLICoords(coord)

    await unlockPrimaryAccountPrompt()

    const landProxyAddress =
      config.contracts[buidlerArguments.network].LAND_PROXY_ADDRESS
    const registry = getContractAt('LANDRegistry', landProxyAddress)

    await registry.assignNewParcel(x, y, beneficiary)
  })
