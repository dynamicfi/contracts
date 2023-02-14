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
  const DyBUSDVenus = await hre.ethers.getContractFactory("DyBEP20VenusProxy");
  const dyBUSDVenus = await upgrades.deployProxy(DyBUSDVenus, [
    "0xc65ee8150C42646Ec14ab7c6070d9623c733aA1E", // BorrowVenus
    "0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56", // BUSD
    "Dynamic BUSD",
    "DyBUSD",
    "0x95c78222B3D6e262426483D42CfA53685A67Ab9D", // vBUSD
    "0xfD36E2c2a6789Db23113685031d7F16329158384", // Unitroller
    "0xB9e0E753630434d7863528cc73CB7AC638a7c8ff", // xvsAddress
    "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c", // WBNB
    "0x8ac76a51cc950d9822d68b83fe1ad97b32cd580d", // USD
    "0x10ED43C718714eb63d5aA57B78B54704E256024E", // Pancake Router
    {
      leverageLevel: 15000,
      leverageBips: 10000,
      minMinting: "10000", // 0.1 USDT
    }
  ]);

  await dyBUSDVenus.deployed();

  console.log("DyBUSDVenus deployed to:", dyBUSDVenus.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
