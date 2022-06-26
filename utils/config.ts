import * as dotenv from "dotenv";
import env from "env-var";

dotenv.config({ path: ".env" });

export const secretConfig = {
  infuraApiKey: env.get("INFURA_API_KEY").required(true).asString(),
  etherscanApiKey: env.get("ETHERSCAN_API_KEY").required(true).asString(),
  coinmarketcapApiKey: env
    .get("COINMARKETCAP_API_KEY")
    .required(false)
    .asString(),
  privateKey: env.get("PRIVATE_KEY").required(true).asString(),
};

export const vrfConfig = {
  vrfCoordinator: env
    .get("VRF_COORDINATOR")
    .default("0x6168499c0cFfCaCD319c818142124B7A15E857ab")
    .asString(),
  linkToken: env
    .get("LINK_TOKEN")
    .default("0x01BE23585060835E02B77ef475b0Cc51aA1e0709")
    .asString(),
  subscriptionId: env.get("SUBSCRIPTION_ID").default("0").asString(),
  keyHash: env
    .get("KEY_HASH")
    .default(
      "0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc"
    )
    .asString(),
  callbackGasLimit: env.get("CALLBACK_GAS_LIMIT").default("100000").asInt(),
  requestConfirmations: env.get("REQUEST_CONFIRMATIONS").default("3").asInt(),
};

export const envConfig = {
  reportGas: env.get("REPORT_GAS").default("true").asBool(),
};
