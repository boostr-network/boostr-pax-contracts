require("ethers");
require("@nomiclabs/hardhat-waffle");
require('dotenv').config()
require("@nomiclabs/hardhat-etherscan");

const ethers = require('ethers');
let mnemonicWallet = ethers.Wallet.fromMnemonic(process.env.MNEMONIC);

module.exports = {
  solidity: {
    version: "0.8.24",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: {
    taraxa_testnet: {
      chainId: 842,
      url: `https://rpc.testnet.taraxa.io`,
      accounts: [mnemonicWallet.privateKey],
    },
    taraxa_mainnet: {
      chainId: 841,
      url: `https://rpc.mainnet.taraxa.io`,
      accounts: [mnemonicWallet.privateKey],
    },
  },
};
