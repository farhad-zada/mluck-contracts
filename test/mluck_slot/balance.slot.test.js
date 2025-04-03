const { expect } = require("chai");
const { ethers } = require("hardhat");
const { Red, Green, Yellow } = require("../../utils/colorize");

describe("MLUCKSlot balance and owning", function () {
  /**
   * @type {import("hardhat").ethers.Contract}
   */
  let busd;
  /**
   * @dev the amount of BUSD required for a single slot to be aqquired.
   */
  let slotPrice = 100n;
  /**
   * @type {import("hardhat").ethers.Contract}
   */
  let mluckSlot;

  let maxSupply = 10000n;

  /**
   * @type {import("hardhat").ethers.HardhatEthersSigner[]}
   */
  let signers;
  this.beforeAll(async () => {
    busd = await ethers.deployContract("BUSD");
    ethers.HardhatEthersSigner;
    signers = await ethers.getSigners();
    await Promise.all(signers.map(signer => busd.transfer(signer.address, ethers.parseEther(100000n.toString()))));
  });

  this.beforeEach(async () => {
    mluckSlot = await ethers.deployContract("MLUCKSlot", ["Springs 8, The Springs, Dubai", "MLUCK", busd.target]);
  });

  it("should show balance", async () => {
    expect(mluckSlot.balanceOf(signers[0])).to.be.ok;
  });

  it("balance should equal to 0", async () => {
    expect(await mluckSlot.balanceOf(signers[0].address)).to.be.equal(0n);
  });

  it("balance should be adequate to minted amount", async () => {
    let mintAmount = 25n;
    let tokenIds = [];
    for (let tokenId = 1n; tokenId <= mintAmount; tokenId++) {
      tokenIds.push(tokenId);
    }
    let signer = signers[2];
    signerMluckSlot = mluckSlot.connect(signer);
    let balanceBeforeMint = await mluckSlot.balanceOf(signer);
    await busd.approve(mluckSlot.target, ethers.parseEther((mintAmount * slotPrice).toString()));
    await mluckSlot.mintBatch(signer, tokenIds);
    let balanceAfterMint = await mluckSlot.balanceOf(signer);
    expect(balanceAfterMint).to.be.equal(mintAmount);
    expect(balanceAfterMint - balanceBeforeMint).to.be.equal(mintAmount);
  });

  it("should deduct exact amount from BUSD balance for mint", async () => {
    let signer = signers[3];
    let tokenId = 1n;
    await busd.connect(signer).approve(mluckSlot.target, ethers.parseEther(slotPrice.toString()));

    const busdBalanceBefore = await busd.balanceOf(signer);
    await expect(await mluckSlot.connect(signer).mint(signer, tokenId)).to.be.ok.and.to.emit(busd, "Transfer");
    const busdBalanceAfter = await busd.balanceOf(signer);
    expect(busdBalanceAfter - busdBalanceBefore).to.be.equal(ethers.parseEther((-1n * slotPrice).toString()));
  });

  it("should deduct exact amount from BUSD balance for mintBatch", async () => {
    let signer = signers[3];
    let tokenIds = [1n, 2n, 3n, 4n];
    await busd
      .connect(signer)
      .approve(mluckSlot.target, ethers.parseEther((BigInt(tokenIds.length) * slotPrice).toString()));

    const busdBalanceBefore = await busd.balanceOf(signer);
    await expect(await mluckSlot.connect(signer).mintBatch(signer, tokenIds)).to.be.ok.and.to.emit(busd, "Transfer");
    const busdBalanceAfter = await busd.balanceOf(signer);
    expect(busdBalanceAfter - busdBalanceBefore).to.be.equal(
      ethers.parseEther((BigInt(-1 * tokenIds.length) * slotPrice).toString())
    );
  });

  it.only("should decrease balance on transfer", async () => {
    let signer1 = signers[1];
    let signer2 = signers[2];

    let signer1Slots = [1n, 2n, 3n, 4n];

    await expect(await mluckSlot.balanceOf(signer1.address)).to.be.equal(0n);
    await busd
      .connect(signer1)
      .approve(mluckSlot.target, ethers.parseEther((BigInt(signer1Slots.length) * slotPrice).toString()));
    await mluckSlot.connect(signer1).mintBatch(signer1, signer1Slots);
    await expect(await mluckSlot.balanceOf(signer1.address)).to.be.equal(BigInt(signer1Slots.length));
    await mluckSlot.connect(signer1).safeTransferFrom(signer1, signer2, signer1Slots[0]);
    await expect(await mluckSlot.balanceOf(signer1)).to.be.equal(3n);
    let slotsOfSigner1 = await mluckSlot.ownedBy(signer1.address);
    expect(slotsOfSigner1.length).to.be.equal(3);
    let slotsOfSigner2 = await mluckSlot.ownedBy(signer2.address);
    expect(slotsOfSigner2.length).to.be.equal(1);
  });

  it("should decrease balance on batch transfer", async () => {
    let signer1 = signers[1];
    let signer2 = signers[2];

    let signer1Slots = [1n, 2n, 3n, 4n];

    await expect(await mluckSlot.balanceOf(signer1.address)).to.be.equal(0n);
    await busd
      .connect(signer1)
      .approve(mluckSlot.target, ethers.parseEther((BigInt(signer1Slots.length) * slotPrice).toString()));
    await mluckSlot.connect(signer1).mintBatch(signer1, signer1Slots);
    await expect(await mluckSlot.balanceOf(signer1.address)).to.be.equal(BigInt(signer1Slots.length));
    await mluckSlot.connect(signer1).transferBatch([signer2, signer2, signer2, signer2], signer1Slots);
    await expect(await mluckSlot.balanceOf(signer1)).to.be.equal(0n);
    let slotsOfSigner2 = await mluckSlot.ownedBy(signer2.address);
    expect(slotsOfSigner2.length).to.be.equal(signer1Slots.length);
  });
});
