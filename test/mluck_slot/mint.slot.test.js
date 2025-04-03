const { expect } = require("chai");
const { ethers } = require("hardhat");
const {Green, Yellow} = require("../../utils/colorize");

describe("MLUCKSlot Mint", function () {
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

  it("should successfully mint the token ID 1", async function () {
    const slotId = 1n;
    expect(await busd.approve(mluckSlot.target, ethers.parseEther(slotPrice.toString())));
    const trx = mluckSlot.mint(mluckSlot.runner.address, slotId);
    expect(await trx).to.be.ok;
    expect(await mluckSlot.ownerOf(slotId)).to.be.equal(mluckSlot.runner.address);
  });

  it("should successfully mint the token with max id (10000)", async function () {
    const slotId = 10000n;
    expect(await busd.approve(mluckSlot.target, ethers.parseEther(slotPrice.toString())));
    const trx = mluckSlot.mint(mluckSlot.runner.address, slotId);
    expect(await trx).to.be.ok;
    expect(await mluckSlot.ownerOf(slotId)).to.be.equal(mluckSlot.runner.address);
  });

  it("should revert minting with token ID over max id bound (10000)", async function () {
    const slotId = 10001n;
    expect(await busd.approve(mluckSlot.target, ethers.parseEther(slotPrice.toString())));
    const trx = mluckSlot.mint(mluckSlot.runner.address, slotId);
    await expect(trx).to.be.revertedWithCustomError(mluckSlot, "MLUCKSlotTokenIdOutOfRange").withArgs(10001n);
    await expect(mluckSlot.ownerOf(slotId))
      .to.be.revertedWithCustomError(mluckSlot, "ERC721NonexistentToken")
      .withArgs(10001n);
  });

  it("should not allow reminting a token by the SAME WALLET AND TOKEN ID (24)", async function () {
    const slotId = 24n;
    expect(await busd.approve(mluckSlot.target, ethers.parseEther((slotPrice * 2n).toString()))).to.be.ok;
    expect(await mluckSlot.mint(mluckSlot.runner.address, slotId)).to.be.ok;
    await expect(mluckSlot.mint(mluckSlot.runner.address, slotId))
      .to.be.revertedWithCustomError(mluckSlot, "ERC721InvalidSender")
      .withArgs(ethers.ZeroAddress);
    expect(await mluckSlot.ownerOf(slotId)).to.be.equal(mluckSlot.runner.address);
  });

  it(`should not allow reminting a token by ${Yellow("DIFFERENT")} WALLET AND ${Yellow(
    "SAME"
  )} TOKEN ID (24)`, async function () {
    const slotId = 24n;
    const firstSigner = signers[0];
    const secondSigner = signers[1];
    expect(mluckSlot.runner.address).to.be.equal(firstSigner.address);
    expect(await busd.approve(mluckSlot.target, ethers.parseEther(slotPrice.toString()))).to.be.ok;
    expect(await mluckSlot.mint(mluckSlot.runner.address, slotId)).to.be.ok;
    // connect to second wallet
    mluckSlot = mluckSlot.connect(secondSigner);
    expect(mluckSlot.runner.address).to.be.equal(secondSigner.address);

    busd = busd.connect(secondSigner);
    expect(await busd.approve(mluckSlot.target, ethers.parseEther(slotPrice.toString()))).to.be.ok;
    await expect(mluckSlot.mint(secondSigner.address, slotId))
      .to.be.revertedWithCustomError(mluckSlot, "ERC721InvalidSender")
      .withArgs(ethers.ZeroAddress);
    expect(await mluckSlot.ownerOf(slotId)).to.be.equal(firstSigner.address);
  });

  it(Green("everyone") + " can buy/mint a token", async function () {
    let slotId = 1n;
    await expect(
      await Promise.all(
        signers.map(signer => {
          let signerBusd = busd.connect(signer);
          return signerBusd.approve(mluckSlot.target, ethers.parseEther(slotPrice.toString()));
        })
      )
    ).to.be.ok;
    expect(
      await Promise.all(
        signers.map(signer => {
          mluckSlotWithThisSigner = mluckSlot.connect(signer);
          return mluckSlotWithThisSigner.mint(signer.address, slotId++);
        })
      )
    ).to.be.ok;
  });

  it("should mint all of tokens for " + Yellow("various") + " wallets.", async function () {
    let slotId = 1n;
    // approve amounts
    await expect(await mluckSlot.totalSupply()).to.be.equal(0n);
    let allowance = (maxSupply / BigInt(signers.length)) * slotPrice + 100n;
    await expect(
      await Promise.all(
        signers.map(signer => {
          let signerBusd = busd.connect(signer);
          return signerBusd.approve(mluckSlot.target, ethers.parseEther(allowance.toString()));
        })
      )
    ).to.be.ok;
    let batchSize = maxSupply / BigInt(signers.length);
    expect(
      await Promise.all(
        signers.map(signer => {
          mluckSlotWithThisSigner = mluckSlot.connect(signer);
          let lastSlotId = slotId + batchSize;
          let batch = [];
          for (; slotId < lastSlotId; slotId++) {
            batch.push(slotId);
          }
          return mluckSlotWithThisSigner.mintBatch(signer.address, batch);
        })
      )
    ).to.be.ok;
    if (slotId < maxSupply) {
      let remainder = [];
      let signerMluckSlot = mluckSlot.connect(signers[0]);
      for (; slotId < maxSupply; slotId++) {
        remainder.push(slotId);
      }
      let tx = signerMluckSlot.mintBatch(signer.address, remainder);
      expect(await tx).to.be.ok;
    }
    expect(await mluckSlot.totalSupply()).to.be.equal(maxSupply);
  });
});
