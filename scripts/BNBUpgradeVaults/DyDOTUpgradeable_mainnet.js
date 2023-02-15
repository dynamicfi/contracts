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

  const DY_DOT_ADDRESS = "0x1ccd19d2Cf70deE0c5a2Db1066b96BeB18190D27";

  const DyDOTVenus = await hre.ethers.getContractFactory("DyBEP20VenusProxy");
  await upgrades.upgradeProxy(DY_DOT_ADDRESS, DyDOTVenus);

  console.log("DyDOTVenus upgraded successfully");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
