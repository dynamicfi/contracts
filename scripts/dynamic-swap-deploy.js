// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
require("dotenv").config();

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const DynamicSwap = await hre.ethers.getContractFactory("DynamicSwap");
  const dynamic = await DynamicSwap.deploy(
    process.env.UNISWAP_V2_ROUTER,
    process.env.WETH,
    5000000000
  );
  // hre.ethers.
  await dynamic.deployed();
  console.log("dynamic deployed to:", dynamic.address);

  const tx = await dynamic.swapEthForToken(
    0,
    [
      "0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd",
      "0x9a01bf917477dD9F5D715D188618fc8B7350cd22"
    ],
    "0xE2B369959AF533de62861B75184b24ddA29114A9",
    "1658827295",
    { value: "1000000000000000" }
  );
  console.log("tx", tx);

  const res = await dynamic.getAmountsOut(
    hre.ethers.utils.parseEther("50000"),
    [
      "0xE02dF9e3e622DeBdD69fb838bB799E3F168902c5",
      "0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd",
    ]
  );
  console.log("res", res);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
