// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
const { upgrades } = require("hardhat");
require("dotenv").config();

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const CrossChain = await hre.ethers.getContractFactory("CrossChain");

  const crossChain = await upgrades.deployProxy(CrossChain, [
    "20", // fee
    "0x10ED43C718714eb63d5aA57B78B54704E256024E", // Router address
    "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c", // WBNB
  ]);

  await crossChain.deployed();
  console.log("dynamic CrossChain deployed to:", crossChain.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
