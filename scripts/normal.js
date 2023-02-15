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
  const NormalDeploy = await hre.ethers.getContractFactory("MiddleProtocol");
  const normalDeploy = await NormalDeploy.deploy(
    "0x0878025B1D4362c3787121BFE7668a3fE031dB4C"
  );

  await normalDeploy.deployed();

  console.log("NormalDeploy deployed to:", normalDeploy.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
