const { BN, expectRevert, time } = require("@openzeppelin/test-helpers");
const { ethers } = require("hardhat");
const Web3 = require("web3");
const web3 = new Web3();
const { expect } = require("chai");
const ether = require("@openzeppelin/test-helpers/src/ether");

describe("Staking", function () {
  const ONE_DAY_IN_SECONDS = 24 * 60 * 60;
  const ONE_HOUR_IN_SECONDS = 60 * 60;
  const THIRTY_DAYS_IN_SECONDS = 30 * ONE_DAY_IN_SECONDS;
  const NINETY_DAYS_IN_SECONDS = 90 * ONE_DAY_IN_SECONDS;

  before(async function () {
    this.TestToken = await ethers.getContractFactory("TestToken");
    this.Staking = await ethers.getContractFactory("Staking");
  });

  beforeEach(async function () {
    [this.owner, this.mainAccount] = await ethers.getSigners();
    this.testToken = await this.TestToken.deploy();
    this.stakingContract = await this.Staking.deploy(this.testToken.address);
    await this.stakingContract.deployed();
  });

  describe("Staking", async function () {
    beforeEach(async function () {
      await this.stakingContract.setEnabled(true);
      await this.testToken.transfer(
        this.stakingContract.address,
        web3.utils.toWei("100000")
      );
      await this.testToken.approve(
        this.stakingContract.address,
        web3.utils.toWei("100000")
      );
    });

    it("should staking success", async function () {
      await this.stakingContract.stake(
        web3.utils.toWei("1000"),
        THIRTY_DAYS_IN_SECONDS
      );
      const stakingIds = await this.stakingContract.getStakingIds();
      console.log(stakingIds);
      await ethers.provider.send("evm_increaseTime", [
        ONE_DAY_IN_SECONDS * 10 + 160,
      ]);
      await ethers.provider.send("evm_mine");
      const currentInterest = await this.stakingContract.getInterest(0);
      console.log(web3.utils.fromWei(currentInterest.toString()));
      await this.stakingContract.claim(0);
      await ethers.provider.send("evm_increaseTime", [
        ONE_DAY_IN_SECONDS * 30 + 160,
      ]);
      await ethers.provider.send("evm_mine");
      const currentInterest2 = await this.stakingContract.getInterest(0);
      await this.stakingContract.withdraw(0);
      console.log(web3.utils.fromWei(currentInterest2.toString()));
      const stakingIds2 = await this.stakingContract.getStakingIds();
      console.log(stakingIds2);
    });

    // it("should withdraw after 2 days success", async function () {
    //   const stakingIds = await this.stakingContract
    //     .connect(this.mainAccount)
    //     .getStakingIds(this.mainAccount.address);
    //   // const stakingId = stakingIds[0];
    //   await ethers.provider.send("evm_increaseTime", [ONE_DAY_IN_SECONDS * 2 + 100]);
    //   await ethers.provider.send("evm_mine");
    //   let balance = await this.cow.balanceOf(this.mainAccount.address);
    //   await this.stakingContract.connect(this.mainAccount).withdraw(0);
    //   let balanceAfterWithdraw = await this.cow.balanceOf(
    //     this.mainAccount.address
    //   );
    //   let interest = balanceAfterWithdraw.sub(balance);
    //   expect(interest).to.be.equal(web3.utils.toWei("40000"));
    //   let nftOwner = await this.cowNFT.ownerOf(0);
    //   expect(nftOwner).to.be.equal(this.mainAccount.address);
    // });
  });
});
