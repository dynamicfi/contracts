const hre = require("hardhat");

async function main() {
  const Staking = await hre.ethers.getContractFactory("Staking");
  const STAKING_TOKEN = "0x7783c490B6D12E719A4271661D6Eb03539eB9BC9";
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
