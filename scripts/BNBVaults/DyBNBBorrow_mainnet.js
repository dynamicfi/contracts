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
  const DyBNBBorrow = await hre.ethers.getContractFactory("DyBNBBorrow");

  // const dyBNBBorrow = await DyBNBBorrow.deploy(
  //   "0x94d1820b2D1c7c7452A163983Dc888CEC546b77D", // Unitroller
  //   "100", // borrowFees
  //   "10000", // borrowDivisor
  //   "0xd61c7Fa07dF7241812eA6D21744a61f1257D1818" // Oracle
  // );
  const dyBNBBorrow = await upgrades.deployProxy(DyBNBBorrow, [
    "0xfD36E2c2a6789Db23113685031d7F16329158384", // Unitroller
    "100", // borrowFees
    "10000", // borrowDivisor
    "0x516c18DC440f107f12619a6d2cc320622807d0eE", // Oracle
  ]);

  await dyBNBBorrow.deployed();

  console.log("DyBNBBorrow deployed to:", dyBNBBorrow.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
