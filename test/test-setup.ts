import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { LotteryFactory, LotteryFactory__factory } from "../typechain";
import { vrfConfig } from "./../utils/config";

export const deployParams = { ...vrfConfig };

export const setupContract = async (
  ownerWallet: SignerWithAddress
): Promise<LotteryFactory> => {
  const lotteryFactory = await new LotteryFactory__factory(ownerWallet).deploy(
    deployParams.vrfCoordinator,
    deployParams.linkToken,
    deployParams.keyHash,
    deployParams.subscriptionId,
    deployParams.callbackGasLimit,
    deployParams.requestConfirmations
  );

  return lotteryFactory;
};
