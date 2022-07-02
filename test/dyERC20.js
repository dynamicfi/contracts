const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("DyERC20", function () {
  it("Should deposit token and return dyToken", async function () {
    const TestToken = await ethers.getContractFactory("TestToken");
    const DyERC20 = await ethers.getContractFactory("DyERC20");

    const [addr1, addr2] = await ethers.getSigners();

    const testToken = await TestToken.deploy();
    const dyErc20 = await DyERC20.deploy(testToken.address, "dyTestToken", "dyTestToken");
    await dyErc20.deployed();

    const amountDeposit = "10000000000000000000";

    await testToken.connect(addr1).approve(dyErc20.address, amountDeposit);
    await dyErc20.connect(addr1).mint(amountDeposit);

    expect(await testToken.balanceOf(dyErc20.address)).to.equal(amountDeposit);
    expect(await dyErc20.balanceOf(addr1.address)).to.equal(amountDeposit);
    
    // await testToken.connect(addr1).transfer(dyErc20.address, amountDeposit);
    // await testToken.connect(addr1).transfer(addr2.address, amountDeposit);

    // await testToken.connect(addr2).approve(dyErc20.address, amountDeposit);

    // await dyErc20.connect(addr2).mint(amountDeposit);

    // console.log(await dyErc20.balanceOf(addr2.address))
  });
});
