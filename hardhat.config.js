require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades")
require("hardhat-deploy");
require("solidity-coverage"); // 新增：注册覆盖率插件 

const SEPOLIA_RPC_URL = process.env.SEPOLIA_RPC_URL || "";
const PRIVATE_KEY = process.env.PRIVATE_KEY || "";
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY || "";
/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.28",
    networks: {
    hardhat: {},
    // sepolia: {
    //   url: SEPOLIA_RPC_URL,
    //   accounts: [PRIVATE_KEY],
    //   chainId: 11155111,
    // },
  },
  // etherscan: {
  //   apiKey: ETHERSCAN_API_KEY,
  // },
  namedAccounts: {
    deployer: { default: 0 },
  },
};
