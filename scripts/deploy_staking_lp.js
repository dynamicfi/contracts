const hre = require("hardhat");

async function main() {
  const StakingLP = await hre.ethers.getContractFactory("StakingLP");
  const LP_TOKEN = "0xffd0af13aa336ccfada425c98be38009d26aa86e";
  const ROUTER = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D";
  const TOKEN = "0x7783c490B6D12E719A4271661D6Eb03539eB9BC9";
  const staking = await StakingLP.deploy(
    LP_TOKEN,
    ROUTER,
    TOKEN
  );
  await staking.deployed();
  console.log("Staking LP deployed to:", staking.address);
}

// sudo npx hardhat verify 0x58B67180DBf6Cc26CbF307c7B794462f00EC6AAe --network goerli "0xffd0af13aa336ccfada425c98be38009d26aa86e" "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D" "0x7783c490B6D12E719A4271661D6Eb03539eB9BC9"

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
