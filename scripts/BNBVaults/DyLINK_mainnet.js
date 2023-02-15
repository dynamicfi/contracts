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
  const DyLinkVenus = await hre.ethers.getContractFactory("DyBEP20VenusProxy");
  const dyLinkVenus = await upgrades.deployProxy(DyLinkVenus, [
    "0xAa6697f60D6EE712871C4933fAeF25E4051038ff", // BorrowVenus
    "0xf8a0bf9cf54bb92f17374d9e9a321e6a111a51bd", // Link
    "Dynamic Link",
    "DyLink",
    "0x650b940a1033b8a1b1873f78730fcfc73ec11f1f", // vLink
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

  await dyLinkVenus.deployed();

  console.log("DyLinkVenus deployed to:", dyLinkVenus.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
