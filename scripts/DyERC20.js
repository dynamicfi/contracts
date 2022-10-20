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
    "0x7da3c5Adea9489c64bBA62B7CF64B8B9cc861184", // LINK
    "Dynamic LINK",
    "DyLINK",
    "0xFAce851a4921ce59e912d19329929CE6da6EB0c7", // cLINK
    "0x627EA49279FD0dE89186A58b8758aD02B6Be2867", // Unitroller
    "0xe16C7165C8FeA64069802aE4c4c9C320783f2b6e",
    "0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6",
    "0x7783c490B6D12E719A4271661D6Eb03539eB9BC9", // dyna
    "0xD87Ba7A50B2E7E660f678A895E4B72E7CB4CCd9C",
    "0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45",
    {
      leverageLevel: 15000,
      leverageBips: 10000,
      minMinting: "10000", // 0.1 USDC
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
