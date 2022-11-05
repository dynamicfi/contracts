// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
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
  const crossChain = await CrossChain.deploy(
    "10000000000000000", // fee
    "0xD99D1c33F9fC3444f8101754aBC46c52416550D1", // Router address
    "0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd" // WETH
  );
  // hre.ethers.
  await crossChain.deployed();
  console.log("dynamic CrossChain deployed to:", crossChain.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
