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
  const TokenTestnet = await hre.ethers.getContractFactory("IPriceOracle");
  const tokenTestnet = await TokenTestnet.attach(
    "0xd61c7Fa07dF7241812eA6D21744a61f1257D1818"
  );

  const value = await tokenTestnet.getUnderlyingPrice(
    "0xA11c8D9DC9b66E209Ef60F0C8D969D3CD988782c"
  );

  console.log("value: ", value.toString());
  console.log("interact successfully");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
