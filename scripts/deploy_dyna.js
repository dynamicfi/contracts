const hre = require("hardhat");

async function main() {
  const DYNA = await hre.ethers.getContractFactory("Dynamic");
  const dy = await DYNA.deploy();
  await dy.deployed();
  console.log("Dyna deployed to:", dy.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});