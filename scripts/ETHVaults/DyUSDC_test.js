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
    "0x07865c6E87B9F70255377e024ace6630C1Eaa37F", // USDC
    "Dynamic USDC",
    "DyUSDC",
    "0x73506770799Eb04befb5AaE4734e58C2C624F493", // cUSDC
    "0x3cBe63aAcF6A064D32072a630A3eab7545C54d78", // Unitroller
    "0x3587b2F7E0E2D6166d6C14230e7Fe160252B0ba4", // compAddress
    "0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6", // WETH
    "0x7783c490B6D12E719A4271661D6Eb03539eB9BC9", // dyna
    "0x79C950C7446B234a6Ad53B908fBF342b01c4d446", // USD
    "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D", // Uniswap Router
    {
      leverageLevel: 15000,
      leverageBips: 10000,
      minMinting: "10000", // 0.1 USDC
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
