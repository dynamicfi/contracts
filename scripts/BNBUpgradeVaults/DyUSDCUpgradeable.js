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

  const DY_USDC_ADDRESS = "0xC7aEaCA1978DE231DDe3e3fa255dA2aF8e38FA94";

  const DyUSDCVenus = await hre.ethers.getContractFactory("DyBEP20VenusProxy");
  await upgrades.upgradeProxy(DY_USDC_ADDRESS, DyUSDCVenus);

  console.log("DyUSDCVenus upgraded successfully");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
