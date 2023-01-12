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
  const EarnLogic = await hre.ethers.getContractFactory("EarnLogic");
  const earnLogic = await EarnLogic.deploy(
    "0x7783c490B6D12E719A4271661D6Eb03539eB9BC9",
    "0x0878025B1D4362c3787121BFE7668a3fE031dB4C",
    "0x0878025B1D4362c3787121BFE7668a3fE031dB4C"
  );

  await earnLogic.deployed();

  console.log("Earn Logic Contract deployed to: ", earnLogic.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
