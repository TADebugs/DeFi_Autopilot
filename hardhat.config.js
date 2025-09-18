require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

const PRIVATE_KEY = process.env.PRIVATE_KEY;

// Generate a dummy private key if none provided (for compilation only)
const DUMMY_PRIVATE_KEY = "0x1234567890123456789012345678901234567890123456789012345678901234";

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.19",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: {
    hardhat: {
      chainId: 1337
    },
    // Flare Mainnet
    flare: {
      url: "https://flare-api.flare.network/ext/bc/C/rpc",
      chainId: 14,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [DUMMY_PRIVATE_KEY],
      gasPrice: 25000000000, // 25 gwei
    },
    // Flare Testnet (Coston2)
    flareTestnet: {
      url: "https://coston2-api.flare.network/ext/bc/C/rpc",
      chainId: 114,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [DUMMY_PRIVATE_KEY],
      gasPrice: 25000000000, // 25 gwei
    },
    // Songbird (Canary Network)
    songbird: {
      url: "https://songbird-api.flare.network/ext/bc/C/rpc",
      chainId: 19,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [DUMMY_PRIVATE_KEY],
      gasPrice: 25000000000,
    }
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
  mocha: {
    timeout: 40000
  },
  etherscan: {
    apiKey: {
      flare: "flare", // placeholder
      flareTestnet: "flare-testnet",
      songbird: "songbird"
    },
    customChains: [
      {
        network: "flare",
        chainId: 14,
        urls: {
          apiURL: "https://flare-explorer.flare.network/api",
          browserURL: "https://flare-explorer.flare.network"
        }
      },
      {
        network: "flareTestnet",
        chainId: 114,
        urls: {
          apiURL: "https://coston2-explorer.flare.network/api",
          browserURL: "https://coston2-explorer.flare.network"
        }
      },
      {
        network: "songbird",
        chainId: 19,
        urls: {
          apiURL: "https://songbird-explorer.flare.network/api",
          browserURL: "https://songbird-explorer.flare.network"
        }
      }
    ]
  }
};