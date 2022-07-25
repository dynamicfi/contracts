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
  const DyBEP20Venus = await hre.ethers.getContractFactory("DyBEP20Venus");
  const dyBep20Venus = await DyBEP20Venus.deploy(
    "0x8301F2213c0eeD49a7E28Ae4c3e91722919B8B47", // BUSD
    "Dynamic BUSD",
    "DyBUSD",
    "0x08e0A5575De71037aE36AbfAfb516595fE68e5e4", // Venus BUSD
    "0x94d1820b2D1c7c7452A163983Dc888CEC546b77D",
    "0xB9e0E753630434d7863528cc73CB7AC638a7c8ff",
    "0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd",
    "0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3",
    {
      leverageLevel: 15000,
      leverageBips: 10000,
      minMinting: "10000000000000000000", // 10BUSD
    }
  );

  await dyBep20Venus.deployed();

  console.log("DyBEP20Venus deployed to:", dyBep20Venus.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
