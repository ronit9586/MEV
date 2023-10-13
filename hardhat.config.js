require('@atixlabs/hardhat-time-n-mine')
require('@nomiclabs/hardhat-etherscan')
require('dotenv').config()
const { ethers } = require('ethers')
require('@openzeppelin/hardhat-upgrades');
require("@nomicfoundation/hardhat-chai-matchers")

const dev = process.env.DEV_PRIVATE_KEY
const prod = process.env.PROD_PRIVATE_KEY

module.exports = {
  solidity: {
    compilers: [
      {
        version: '0.8.0',
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      }, 
      {
        version: '0.4.20',
        settings: {
          optimizer: {
            enabled: true,
            runs: 1,
          },
        },
      },
    ],
  },
  networks: {
    fuji: {
      url: 'https://api.avax-test.network/ext/bc/C/rpc',
      accounts: dev ? [dev] : dev,
    },
    mumbai: {
      url: 'https://matic-mumbai.chainstacklabs.com',
      accounts: dev ? [dev] : dev,
    },
    matic: {
      url: "https://polygon-mainnet.g.alchemy.com/v2/2xb1hySVAh9Sz5C-loghXbHe6NH-BWTU",
      accounts: prod ? [prod] : prod,
    },

    bsctestnet: {
      url: 'https://data-seed-prebsc-2-s2.binance.org:8545',
      accounts: dev ? [dev] : dev,
      gas: 2100000,
      gasPrice: 10000000000, //ethers.utils.parseUnits('1.2', 'gwei').toNumber(),
    },  
    localhost: {
      url: 'http://127.0.0.1:8545/',
      accounts: dev ? ["0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80", "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d", "0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a", "0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6"] : dev,
      gas: 2100000,
      gasPrice: 500000000000, //ethers.utils.parseUnits('1.2', 'gwei').toNumber(),
    },
  },
  etherscan: {
    apiKey: "T4A58D6AI7PPUBT8IXP16PSQY9V67WJ41R"
    // apiKey: "TRG7E3JX6GJI6XKYIXNC7F353VXGJG84R1"
  },
  mocha: {
    timeout: 5 * 60 * 10000,
  },
}
