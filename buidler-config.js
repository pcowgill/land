const HDWalletProvider = require('truffle-hdwallet-provider')
const mnemonic = '' // 12 word mnemonic

require('./scripts/cmd')

module.exports = {
  contracts: {
    ropsten: {
      LAND_PROXY_ADDRESS: '0x7a73483784ab79257bb11b96fd62a2c3ae4fb75b'
    },
    mainnet: {
      LAND_PROXY_ADDRESS: '0xf87e31492faf9a91b02ee0deaad50d51d56d5d4d'
    }
  },
  networks: {
    imainnet: {
      provider: () =>
        new HDWalletProvider(mnemonic, 'https://mainnet.infura.io/'),
      gas: 70000000,
      network_id: 1
    },
    iropsten: {
      provider: () =>
        new HDWalletProvider(mnemonic, 'https://ropsten.infura.io/'),
      network_id: 3,
      gas: 30000000
    },
    mainnet: {
      host: 'localhost',
      port: 8545,
      gas: 70000000,
      network_id: 1
    },
    ropsten: {
      host: 'localhost',
      port: 8545,
      gas: 30000000,
      network_id: 3
    },
    development: {
      host: 'localhost',
      port: 18545,
      gas: 100000000,
      network_id: '*'
    }
  }
}
