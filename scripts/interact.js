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
  const TokenTestnet = await hre.ethers.getContractFactory("TestnetToken");
  const tokenTestnet = await TokenTestnet.attach(
    "0x07865c6E87B9F70255377e024ace6630C1Eaa37F"
  );

  await tokenTestnet.approve(
    "0x5892276C810372f56513282d1c684f89B4BBbbAC",
    "1000000"
  );

  console.log("interact successfully");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
