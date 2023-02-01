const hre = require("hardhat");

async function main() {
  const StakingDynaLP = await hre.ethers.getContractFactory("StakingDynaLP");
  const LP_TOKEN = "0xb6148c6fA6Ebdd6e22eF5150c5C3ceE78b24a3a0";
  const ROUTER = "0x10ED43C718714eb63d5aA57B78B54704E256024E";
  const TOKEN = "0x5c0d0111ffc638802c9EfCcF55934D5C63aB3f79";
  
  // bsc network
  // const LP_TOKEN = "0x540dcd1b2869455bf407c77d07d3f2c94ae477b7";
  // const ROUTER = "0x9ac64cc6e4415144c455bd8e4837fea55603e5c3";
  // const TOKEN = "0x26A997cA86Ee880fc90DF3f29dC09b34bA3140e3";
  const staking = await StakingDynaLP.deploy(
    LP_TOKEN,
    ROUTER,
    TOKEN
  );
  await staking.deployed();
  console.log("StakingDynaLP deployed to:", staking.address);
}

// sudo npx hardhat verify 0xa05018cD4e19FeE6eAF51e334C9083f156735716 --network goerli "0xffd0af13aa336ccfada425c98be38009d26aa86e" "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D" "0x7783c490B6D12E719A4271661D6Eb03539eB9BC9"
// sudo npx hardhat verify 0xCf80c14a7f0aB75EEd68e3E8428f82394d813E80 --network testnet "0x540dcd1b2869455bf407c77d07d3f2c94ae477b7" "0x9ac64cc6e4415144c455bd8e4837fea55603e5c3" "0x26A997cA86Ee880fc90DF3f29dC09b34bA3140e3"

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
