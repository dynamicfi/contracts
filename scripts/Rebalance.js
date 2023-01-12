// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const Rebalance = await hre.ethers.getContractFactory("Rebalance");
  const rebalance = await Rebalance.deploy([
    "0x6918D0b8aB2072bA93f1f02E18df984183e4F576",
    "0xDBd4527d79B76895BA31f7eC68DCe3f287a0354B",
    "0xf740359877183aD9647fa2924597B9112877Cb2d",
  ]);

  await rebalance.deployed();

  console.log("Rebalance deployed to:", rebalance.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
