import hre from "hardhat";
import { LotteryFactory__factory } from "../typechain";
import { vrfConfig } from "./../utils/config";

async function main() {
  console.log("\nGet network");
  const network = await hre.ethers.provider.getNetwork();
  console.log(`Network chain id: ${network.chainId}`);
  console.log(`Network name: ${network.name}`);

  console.log("\nGet wallet");
  const wallet = (await hre.ethers.getSigners())[0];
  console.log(`Wallet address: ${wallet.address}`);

  console.log("\nDeploy contract");
  const deployParams = [
    vrfConfig.vrfCoordinator,
    vrfConfig.linkToken,
    vrfConfig.keyHash,
    vrfConfig.subscriptionId,
    vrfConfig.callbackGasLimit,
    vrfConfig.requestConfirmations,
  ];
  console.log(`Deploy params: ${`"${deployParams.join('", "')}"` || "None"}`);

  console.log("Deploying...");
  const lotteryFactory = await new LotteryFactory__factory(wallet).deploy(
    vrfConfig.vrfCoordinator,
    vrfConfig.linkToken,
    vrfConfig.keyHash,
    vrfConfig.subscriptionId,
    vrfConfig.callbackGasLimit,
    vrfConfig.requestConfirmations
  );
  await lotteryFactory.deployed();

  console.log(`Deployed to address: ${lotteryFactory.address}`);
  console.log(`Transaction id: ${lotteryFactory.deployTransaction.hash}`);
  console.log("Waiting for confirmation transaction...");
  const transactionReceipt = await lotteryFactory.deployTransaction.wait();
  console.log(
    `Transaction confirmed in block: ${transactionReceipt.blockNumber}`
  );
  console.log(`Transaction gas used: ${transactionReceipt.gasUsed}`);

  console.log("\nEtherscan verify script:");
  console.log(
    `npx hardhat verify --network ${network.name} ${
      lotteryFactory.address
    } "${deployParams.join('" "')}"`
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
