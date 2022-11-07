const hre = require("hardhat");

async function main() {
  const StakingLP2 = await hre.ethers.getContractFactory("StakingLP2");
  // const LP_TOKEN = "0xffd0af13aa336ccfada425c98be38009d26aa86e";
  // const ROUTER = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D";
  // const TOKEN = "0x7783c490B6D12E719A4271661D6Eb03539eB9BC9";
  
  // bsc network
  const LP_TOKEN = "0x540dcd1b2869455bf407c77d07d3f2c94ae477b7";
  const ROUTER = "0x9ac64cc6e4415144c455bd8e4837fea55603e5c3";
  const TOKEN = "0x26A997cA86Ee880fc90DF3f29dC09b34bA3140e3";
  const staking = await StakingLP2.deploy(
    LP_TOKEN,
    ROUTER,
    TOKEN
  );
  await staking.deployed();
  console.log("Staking LP 2 deployed to:", staking.address);
}

// sudo npx hardhat verify 0x58B67180DBf6Cc26CbF307c7B794462f00EC6AAe --network goerli "0xffd0af13aa336ccfada425c98be38009d26aa86e" "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D" "0x7783c490B6D12E719A4271661D6Eb03539eB9BC9"
// sudo npx hardhat verify 0xD214445B72E582b83Ad3A9A87db98cfEa5b9DCC3 --network testnet "0x540dcd1b2869455bf407c77d07d3f2c94ae477b7" "0x9ac64cc6e4415144c455bd8e4837fea55603e5c3" "0x26A997cA86Ee880fc90DF3f29dC09b34bA3140e3"

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
