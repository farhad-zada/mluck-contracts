const { expect } = require("chai");
const { ethers } = require("hardhat");
const { Red, Green, Yellow } = require("../../utils/colorize");

describe("MLUCKSlot Owner specific features", function () {
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
    mluckSlot = await ethers.deployContract("MLUCKSlot", ["Springs 8, The Springs, Dubai", "MLUCK", busd.target]);

    let slotId = 1n;
    // approve amounts
    let allowance = (maxSupply / BigInt(signers.length)) * slotPrice;

    await Promise.all(
      signers.map(signer => {
        let signerBusd = busd.connect(signer);
        return signerBusd.approve(mluckSlot.target, ethers.parseEther(allowance.toString()));
      })
    );

    let batchSize = maxSupply / BigInt(signers.length);

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
    );

    if (slotId < maxSupply) {
      let remainder = [];
      let signerMluckSlot = mluckSlot.connect(signers[0]);
      for (; slotId < maxSupply; slotId++) {
        remainder.push(slotId);
      }
      let tx = signerMluckSlot.mintBatch(signer.address, remainder);
    }
    expect(await mluckSlot.totalSupply()).to.be.equal(maxSupply);
  });

  this.beforeEach(async () => {});

  it("is owner of the contract", async () => {
    await expect(await mluckSlot.owner()).to.be.equal(mluckSlot.runner.address);
  });

  it("should put returns", async function () {
    let sharePerSlot = 20n;
    let returnsAmount = ethers.parseEther((maxSupply * sharePerSlot).toString());
    await expect(await busd.approve(mluckSlot.target, returnsAmount)).to.be.ok;
    await expect(await mluckSlot.putReturns(returnsAmount)).to.be.ok;
    await expect(await mluckSlot.connect(signers[1]).sharesTotal()).to.be.equal(returnsAmount);
    await expect(await mluckSlot.connect(signers[3]).sharePerSlot()).to.be.equal(
      ethers.parseEther(sharePerSlot.toString())
    );
  });
});
