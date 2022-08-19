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
  const DyBNBVenus = await hre.ethers.getContractFactory("DyBNBVenus");
  const dyBNBVenus = await DyBNBVenus.deploy(
    "Dynamic BNB",
    "DyBNB",
    "0x2E7222e51c0f6e98610A1543Aa3836E092CDe62c", // Venus BUSD
    "0x94d1820b2D1c7c7452A163983Dc888CEC546b77D",
    "0xB9e0E753630434d7863528cc73CB7AC638a7c8ff",
    "0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd",
    "0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3",
    {
      leverageLevel: 10000,
      leverageBips: 10000,
      minMinting: "100000000000000", // 0.001BNB
    }
  );

  await dyBNBVenus.deployed();

  console.log("DyBNBVenus deployed to:", dyBNBVenus.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
