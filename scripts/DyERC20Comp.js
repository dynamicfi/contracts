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
    "0xC8F88977E21630Cf93c02D02d9E8812ff0DFC37a", // UNI
    "Dynamic cUSDc",
    "DyCompUSDc",
    "0x65280b21167BBD059221488B7cBE759F9fB18bB5", // cUNI
    "0xcfa7b0e37f5AC60f3ae25226F5e39ec59AD26152", // Unitroller
    "0xf76D4a441E4ba86A923ce32B89AFF89dBccAA075",
    "0xc778417E063141139Fce010982780140Aa0cD5Ab",
    "0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45",
    {
      leverageLevel: 15000,
      leverageBips: 10000,
      minMinting: "1000000000000000", // 0.001 UNI
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
