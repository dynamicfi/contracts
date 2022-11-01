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
  const DyUSDCVenus = await hre.ethers.getContractFactory("DyBEP20Venus");
  const dyUSDCVenus = await DyUSDCVenus.deploy(
    "0x16227D60f7a0e586C66B005219dfc887D13C9531", // USDC
    "Dynamic USDC",
    "DyUSDC",
    "0xD5C4C2e2facBEB59D0216D0595d63FcDc6F9A1a7", // vUSDC
    "0x94d1820b2D1c7c7452A163983Dc888CEC546b77D", // Unitroller
    "0xB9e0E753630434d7863528cc73CB7AC638a7c8ff", // xvsAddress
    "0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd", // WBNB
    "0x8188F55Bd52f512fae95F9bc96F24A4e7B9d833d", // dyna
    "0xA11c8D9DC9b66E209Ef60F0C8D969D3CD988782c", // USD
    "0xD99D1c33F9fC3444f8101754aBC46c52416550D1", // Pancake Router
    {
      leverageLevel: 15000,
      leverageBips: 10000,
      minMinting: "10000", // 0.1 USDT
    }
  );

  await dyUSDCVenus.deployed();

  console.log("DyUSDCVenus deployed to:", dyUSDCVenus.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
