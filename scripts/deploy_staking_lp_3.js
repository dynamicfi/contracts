const hre = require("hardhat");

async function main() {
  const StakingLP3 = await hre.ethers.getContractFactory("StakingLP3");
  // const LP_TOKEN = "0xf8b02db66b63dd6ba44778fadf606ff621cf1cc1";
  // const ROUTER = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D";
  // const DAI = "0xdc31ee1784292379fbb2964b3b9c4124d8f89c60";
  // const TOKEN = "0x7783c490B6D12E719A4271661D6Eb03539eB9BC9";
  
  // bsc network
  const LP_TOKEN = "0x30fd11e9909af7dad6fe3fde0ca31347264b705e";
  const ROUTER = "0x9ac64cc6e4415144c455bd8e4837fea55603e5c3";
  const DAI = "0x7ef95a0fee0dd31b22626fa2e10ee6a223f8a684";
  const TOKEN = "0x26A997cA86Ee880fc90DF3f29dC09b34bA3140e3";
  const staking = await StakingLP3.deploy(
    LP_TOKEN,
    ROUTER,
    DAI,
    TOKEN
  );
  await staking.deployed();
  console.log("Staking LP 3 deployed to:", staking.address);
}

// sudo npx hardhat verify 0x0534781dCe2ABB2C5e992C333BbdBdBAC7a5CFAc --network goerli "0xf8b02db66b63dd6ba44778fadf606ff621cf1cc1" "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D" "0xdc31ee1784292379fbb2964b3b9c4124d8f89c60" "0x7783c490B6D12E719A4271661D6Eb03539eB9BC9"
// sudo npx hardhat verify 0xBFAA608e41E8c75ec3B1A3Cb89Db5b87165b3eCe --network testnet "0x30fd11e9909af7dad6fe3fde0ca31347264b705e" "0x9ac64cc6e4415144c455bd8e4837fea55603e5c3" "0x7ef95a0fee0dd31b22626fa2e10ee6a223f8a684" "0x26A997cA86Ee880fc90DF3f29dC09b34bA3140e3"

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
