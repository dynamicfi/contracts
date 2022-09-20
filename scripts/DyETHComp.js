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
  const DyETH20Comp = await hre.ethers.getContractFactory("DyETHCompound");
  const dyETH20Comp = await DyETH20Comp.deploy(
    "Dynamic cETH",
    "DyCompETH",
    "0x859e9d8a4edadfEDb5A2fF311243af80F85A91b8", // cETH
    "0xcfa7b0e37f5AC60f3ae25226F5e39ec59AD26152", // Unitroller
    "0xf76D4a441E4ba86A923ce32B89AFF89dBccAA075",
    "0xc778417E063141139Fce010982780140Aa0cD5Ab",
    "0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45",
    {
      leverageLevel: 15000,
      leverageBips: 10000,
      minMinting: "100000000000000", // 0.0001 ETH
    }
  );

  await dyETH20Comp.deployed();

  console.log("DyETHComp deployed to:", dyETH20Comp.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});