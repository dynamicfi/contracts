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
  const DyUSDCVenus = await hre.ethers.getContractFactory("DyERC20Compound");
  const dyUSDCVenus = await upgrades.deployProxy(DyUSDCVenus, [
    "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48", // USDC
    "Dynamic USDC",
    "DyUSDC",
    "0x39AA39c021dfbaE8faC545936693aC917d5E7563", // cUSDC
    "0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B", // Unitroller
    "0xc00e94Cb662C3520282E6f5717214004A7f26888", // compAddress
    "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2", // WETH
    "0xc00939d63F3B79F3cdf33935A40689959cC09dDF", // dyna
    "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48", // USD
    "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D", // Uniswap Router
    {
      leverageLevel: 15000,
      leverageBips: 10000,
      minMinting: "100000", // 0.1 USDC
    },
  ]);

  await dyUSDCVenus.deployed();

  console.log("DyUSDCCompound deployed to:", dyUSDCVenus.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
