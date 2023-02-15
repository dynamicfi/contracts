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
  const DyADAVenus = await hre.ethers.getContractFactory("DyBEP20VenusProxy");
  const dyADAVenus = await upgrades.deployProxy(DyADAVenus, [
    "0xAa6697f60D6EE712871C4933fAeF25E4051038ff", // BorrowVenus
    "0x3ee2200efb3400fabb9aacf31297cbdd1d435d47", // ADA
    "Dynamic ADA",
    "DyADA",
    "0x9a0af7fdb2065ce470d72664de73cae409da28ec", // vADA
    "0xfD36E2c2a6789Db23113685031d7F16329158384", // Unitroller
    "0xcF6BB5389c92Bdda8a3747Ddb454cB7a64626C63", // xvsAddress
    "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c", // WBNB
    "0x8ac76a51cc950d9822d68b83fe1ad97b32cd580d", // USD
    "0x10ED43C718714eb63d5aA57B78B54704E256024E", // Pancake Router
    {
      leverageLevel: 15000,
      leverageBips: 10000,
      minMinting: "1000000000", // 0.1 USDT
    },
    "18",
  ]);

  await dyADAVenus.deployed();

  console.log("DyADAVenus deployed to:", dyADAVenus.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
