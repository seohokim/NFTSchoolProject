import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  defaultNetwork: 'localhost',
  solidity: {
    version: "0.8.9",
    settings: { optimizer: {enabled:true, runs:200 }}
  },
  networks: {
    localhost: {
      url: "http://127.0.0.1:8545/",
    }
  }
};

export default config;
