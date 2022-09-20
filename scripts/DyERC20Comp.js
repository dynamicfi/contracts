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
  const DyERC20Comp = await hre.ethers.getContractFactory("DyERC20Compound");
  const dyERC20Comp = await DyERC20Comp.deploy(
    "0x07865c6e87b9f70255377e024ace6630c1eaa37f", // USDC
    "Dynamic cUSDc",
    "DyCompUSDc",
    "0x2973e69b20563bcc66dC63Bde153072c33eF37fe", // cUSDC
    "0xcfa7b0e37f5AC60f3ae25226F5e39ec59AD26152", // Unitroller
    "0xf76D4a441E4ba86A923ce32B89AFF89dBccAA075",
    "0xc778417E063141139Fce010982780140Aa0cD5Ab",
    "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D",
    {
      leverageLevel: 15000,
      leverageBips: 10000,
      minMinting: "100000000000000000", // 0.1 USDC
    }
  );

  await dyERC20Comp.deployed();

  console.log("DyERCcomp deployed to:", dyERC20Comp.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});