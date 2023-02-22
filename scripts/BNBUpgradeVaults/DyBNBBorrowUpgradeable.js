// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
const { upgrades } = require("hardhat");

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy

  const DY_BORROW_BNB_ADDRESS = "0xB683bF0390AC74000507ce56cdECDaCA75eb0CFf";

  const DyBorrowVenus = await hre.ethers.getContractFactory("DyBNBBorrow");
  await upgrades.upgradeProxy(DY_BORROW_BNB_ADDRESS, DyBorrowVenus);

  console.log("DyBUSDVenus upgraded successfully");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
