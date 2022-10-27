const hre = require("hardhat");

async function main() {
  const Staking = await hre.ethers.getContractFactory("Staking");
  const STAKING_TOKEN = "0x26A997cA86Ee880fc90DF3f29dC09b34bA3140e3";
  const staking = await Staking.deploy(
    STAKING_TOKEN,
  );
  await staking.deployed();
  console.log("Staking deployed to:", staking.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
