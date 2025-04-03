require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");
require("@nomicfoundation/hardhat-ledger");
require("hardhat-contract-sizer");
require("dotenv").config();

const env = process.env;

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.20",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      {
        version: "0.8.22",
      },
      {
        version: "0.8.2",
      },
    ],
  },
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      chainId: 1337,
    },
    tbsc: {
      url: env.TBSC_RPC,
      accounts: [env.PRIVATE_KEY],
      ledgerAccounts: [env.LEDGER_ACCOUNT],
    },
    bsc: {
      url: env.BSC_RPC,
      accounts: [env.PRIVATE_KEY],
      ledgerAccounts: [env.LEDGER_ACCOUNT],
    },
    pol: {
      url: env.POL_RPC,
      accounts: [env.PRIVATE_KEY],
      ledgerAccounts: [env.LEDGER_ACCOUNT]
    }
  },
  // contractSizer: {
  //   alphaSort: true,
  //   // runOnCompile: true,
  //   disambiguatePaths: false,
  // },
  etherscan: {
    apiKey: {
      bsc: env.BSC_APIKEY,
      polygon: env.POL_APIKEY,
    },
  },
};
