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

  const DY_USDT_ADDRESS = "0x28E45771a24C2BF662b323a43761b43864BE38c3";

  const DyUSDTVenus = await hre.ethers.getContractFactory("DyBEP20Venus");
  await upgrades.forceImport(DY_USDT_ADDRESS, DyUSDTVenus);

  console.log("DyUSDTVenus was force-imported successfully");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
