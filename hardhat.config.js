require('dotenv').config()

require('@nomiclabs/hardhat-etherscan')
require('@nomiclabs/hardhat-web3')
require('@nomiclabs/hardhat-waffle')
require('@openzeppelin/hardhat-upgrades')

require('hardhat-gas-reporter')
require('solidity-coverage')
require('hardhat-contract-sizer')

require("hardhat-interface-generator");
require('hardhat-deploy');
const ethers = require('ethers')

require('./tasks')
const config = require('./config')

function getPrivateKeys () {
  const privateKeys = config.PRIVATE_KEYS
  // if(Object.keys(privateKeys).length === 0){
  //   throw new Error("Please provide private keys in privateKeys.json file for setup")
  // }
  const privateKeysArray = []

  for (const [, value] of Object.entries(privateKeys)) {
    privateKeysArray.push(value)
  }
  return privateKeysArray
}

function getNamedAccounts () {
  const privateKeys = config.PRIVATE_KEYS
  // if(Object.keys(privateKeys).length === 0){
  //   throw new Error("Please provide private keys in privateKeys.json file for setup")
  // }
  const privateKeysObject = {}

  for (const [name, value] of Object.entries(privateKeys)) {
    privateKeysObject[name] = {default : new ethers.Wallet(value).address}
  }
  return privateKeysObject
}


module.exports = {
  solidity: {
    compilers:[
    {
        version: '0.8.4',
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        },
    },
    {
      version: '0.8.9',
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        }
      }
    },
    
    {
      version: '0.8.17',
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        }
      }
    }  
    ]
  },
  networks: {

    local_ganache: {
      url: "http://127.0.0.1:8545",
      accounts: getPrivateKeys()
    },
    
    ethereum: {
      url: config.NETWORKS.ETHEREUM.RPC_URL || '',
      accounts: getPrivateKeys()
    },

    rinkeyby: {
      url: config.NETWORKS.RINKEBY.RPC_URL || '',
      accounts: getPrivateKeys()
    },

    ropsten: {
      url: config.NETWORKS.ROPSTEN.RPC_URL || '',
      accounts: getPrivateKeys()
    },

    goerli: {
      url: config.NETWORKS.GOERLI.RPC_URL || '',
      accounts: getPrivateKeys(),
      timeout: 0
    },

    kovan: {
      url: config.NETWORKS.KOVAN.RPC_URL || '',
      accounts: getPrivateKeys()
    },

    binance_mainnet: {
      url: config.NETWORKS.BINANCE_CHAIN.RPC_URL || '',
      accounts: getPrivateKeys()
    },

    binance_testnet: {
      url: config.NETWORKS.BINANCE_CHAIN_TESTNET.RPC_URL || '',
      accounts: getPrivateKeys()
    },

    polygon_mainnet: {
      url: config.NETWORKS.POLYGON_MAINNET.RPC_URL || '',
      accounts: getPrivateKeys(),
      gasPrice: 200000000000,
      timeout: 0
    },

    polygon_testnet: {
      url: config.NETWORKS.POLYGON_TESTNET.RPC_URL || '',
      accounts: getPrivateKeys(),
      gasPrice: 35000000000,
      timeout: 0
    },
    bttc_testnet: {
      url: config.NETWORKS.BTTC_TESTNET.RPC_URL || '',
      accounts: getPrivateKeys(),
      timeout: 50000
    },
    xdc_testnet: {
      url: config.NETWORKS.XDC_TESTNET.RPC_URL || '',
      accounts: getPrivateKeys(),
      timeout: 50000
    },
    cronos_testnet: {
      url: config.NETWORKS.CRONOS_TESTNET.RPC_URL || '',
      accounts: getPrivateKeys(),
      timeout: 50000
    },

    gnosis_mainnet: {
      url: config.NETWORKS.GNOSIS_MAINNET.RPC_URL || '',
      accounts: getPrivateKeys(),
      timeout: 500000
    },

    sepolia :{
      url: config.NETWORKS.SEPOLIA.RPC_URL || '',
      accounts: getPrivateKeys(),
      timeout: 0
    },

    mch_verse : {
      url: config.NETWORKS.MCH_VERSE.RPC_URL || '',
      accounts: getPrivateKeys(),
      timeout: 0
    },

    optimism_goerli: {
      url: config.NETWORKS.OPTIMISM_GOERLI.RPC_URL || '',
      accounts: getPrivateKeys(),
      timeout: 0
    },





    custom: {
      url: config.NETWORKS.CUSTOM.RPC_URL || '',
      accounts: getPrivateKeys()
    }
  },
  gasReporter: {
    enabled: config.REPORT_GAS,
    currency: 'USD'
  },

  etherscan: {
    apiKey: {
      polygonMumbai: config.POLYGONSCAN_API_KEY,
      sepolia: config.ETHERSCAN_API_KEY,
      goerli: config.ETHERSCAN_API_KEY,
      polygon: config.POLYGONSCAN_API_KEY,
      optimistic_goerli: config.OPTIMISM_API_KEY,
    },
    customChains: [
      {
        network: "optimistic_goerli",
        chainId: 420,
        urls: {
          apiURL: "https://api-goerli-optimistic.etherscan.io/api",
          browserURL: "https://goerli-optimism.etherscan.io"
        }
      }
    ]

  },

  namedAccounts: getNamedAccounts(),

  mocha: {
    timeout: 500000
  }
}
