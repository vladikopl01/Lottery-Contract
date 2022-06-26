import * as dotenv from "dotenv";

import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "hardhat-gas-reporter";
import { HardhatUserConfig, task } from "hardhat/config";
import "solidity-coverage";
import { envConfig, secretConfig } from "./utils/config";

dotenv.config();

task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

const config: HardhatUserConfig = {
  solidity: "0.8.4",
  networks: {
    rinkeby: {
      url: `https://rinkeby.infura.io/v3/${secretConfig.infuraApiKey}`,
      accounts:
        secretConfig.privateKey !== undefined ? [secretConfig.privateKey] : [],
    },
  },
  typechain: {
    outDir: "typechain",
    target: "ethers-v5",
  },
  gasReporter: {
    enabled: envConfig.reportGas !== undefined,
    currency: "USD",
    coinmarketcap: secretConfig.coinmarketcapApiKey,
  },
  etherscan: {
    apiKey: secretConfig.etherscanApiKey,
  },
};

export default config;
