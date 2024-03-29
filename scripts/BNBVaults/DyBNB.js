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
  const DyBNBVenus = await hre.ethers.getContractFactory("DyBNBVenusProxy");

  const dyBNBVenus = await DyBNBVenus.deploy(
    "0x634f032e9b1ffa4Fd268b8AF836AAD331afdA488", // BorrowVenus
    "Dynamic BNB",
    "DyBNB",
    "0x2E7222e51c0f6e98610A1543Aa3836E092CDe62c", // cBNB
    "0x94d1820b2D1c7c7452A163983Dc888CEC546b77D", // Unitroller
    "0xB9e0E753630434d7863528cc73CB7AC638a7c8ff", // xvsAddress
    "0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd", // WBNB
    "0xA11c8D9DC9b66E209Ef60F0C8D969D3CD988782c", // USD
    "0xD99D1c33F9fC3444f8101754aBC46c52416550D1", // Pancake Router
    {
      leverageLevel: 15000,
      leverageBips: 10000,
      minMinting: "10000000000000000", // 0.01 BNB
    }
  );

  await dyBNBVenus.deployed();

  console.log("DyBNBCompound deployed to:", dyBNBVenus.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
