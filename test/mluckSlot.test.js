const { expect } = require("chai")
const { ethers } = require("hardhat")

describe("MLUCKSlot", function () {
  /**
   * @type {import("hardhat").ethers.Contract}
   */
  let mluckSlot;
  /**
   * @type {import("hardhat").ethers.Contract}
   */
  let busd;

  let allowance = 100200n;
  let sharesTotal = 10000n;
  this.beforeAll(async () => {
    busd = await ethers.deployContract("BUSD");
    mluckSlot = await ethers.deployContract("MLUCKSlot", ["1234 Palm Jumeirah, Dubai, UAE", "MLUCK", busd.target]);
    await busd.approve(mluckSlot.target, ethers.parseEther(allowance.toString()));
  })
  it("should deploy MLUCKSlot", function () {
    expect(ethers.isAddress(mluckSlot.runner.address)).to.be.ok
  })

  it("busd total supply should be 1 billion", async function () {
    expect(await busd.totalSupply()).to.equal(ethers.parseEther("10000000000"))
  });

  it("busd balance should be 1 billion", async function () {
    expect(await busd.balanceOf(mluckSlot.runner.address)).to.equal(ethers.parseEther("10000000000"))
  });

  it("busd allowance should be " + allowance.toString(), async function () {
    expect(await busd.allowance(mluckSlot.runner.address, mluckSlot.target)).to.equal(ethers.parseEther(allowance.toString()));
  });

  it("the name should be '1234 Palm Jumeirah, Dubai, UAE'", async function () {
    expect(await mluckSlot.name()).to.equal("1234 Palm Jumeirah, Dubai, UAE")
  })

  it("should mint from 1 - 1000", async function () {
    let tokenIds = []
    for (let i = 1n; i <= 1000n; i++) {
      tokenIds.push(i)
    }

    expect(await mluckSlot.mintBatch(mluckSlot.runner.address, tokenIds)).to.be.ok;
    expect(await mluckSlot.balanceOf(mluckSlot.runner.address)).to.equal(1000)
  })

  it("should revert re-minting", async function () {
    await expect(mluckSlot.mint(mluckSlot.runner.address, 1n)).to.be.revertedWithCustomError(mluckSlot, 'ERC721InvalidSender(address)');
  });

  it("should revert re-minting", async function () {
    await expect(mluckSlot.mintBatch(mluckSlot.runner.address, [1n])).to.be.revertedWithCustomError(mluckSlot, 'ERC721InvalidSender(address)');
  });

  it("should withdraw 10K BUSD", async function () {
    let amount = ethers.parseEther("100000");
    let balanceBeforeWithdraw = await busd.balanceOf(mluckSlot.target);
    await expect(await mluckSlot.withdraw(amount)).to.be.ok;
    let balanceAfterWithdraw = await busd.balanceOf(mluckSlot.target);
    expect(balanceAfterWithdraw).to.equal(balanceBeforeWithdraw - amount);
  });

  it("should set shares total to 10000 BUSD", async function () {
    let amount = ethers.parseEther(sharesTotal.toString());
    // increase allowance first since it has already been spent
    await busd.approve(mluckSlot.target, amount);
    await expect(await mluckSlot.putReturns(amount)).to.be.ok;
    expect(await mluckSlot.sharesTotal()).to.equal(amount);
  })

  it ("should claim for token 1", async function () {
    let tokenId = 1n;
    await expect(mluckSlot.claim(tokenId)).to.be.ok;
  });

  it ("claim should be equal to share amount for token", async function () {
    let tokenId = 2n;
    /**
     * @type {import("hardhat").ethers.TransactionResponse}
     */
    const tx = await mluckSlot.claim(tokenId);
    await tx.wait();

    let claimedAmount = await mluckSlot.tokenClaims(tokenId);
    let sharePerToken = await mluckSlot.sharePerToken();
    expect(claimedAmount).to.be.equal(sharePerToken);
  });

  it(`share per token should be ${sharesTotal} BUSD`, async function () {
    let sharePerToken = await mluckSlot.sharePerToken();
    let maxSupply = await mluckSlot.maxSupply();
    expect(sharePerToken).to.equal(ethers.parseEther((sharesTotal / maxSupply).toString()));
  });

  it("should claim for all tokens", async function () {
  
    let tokenIds = []
    for (let i = 1n; i <= 1000n; i++) {
      tokenIds.push(i)
    }
    const grossClaimable = await mluckSlot.grossClaimable(tokenIds);
    const balanceBeforeClaim = await busd.balanceOf(mluckSlot.target);
    // get the Transfer event on claimAll and log it
    let tx = await mluckSlot.claimAll(tokenIds);
    await expect(tx).to.be.ok.emit(busd, "Transfer").withArgs(mluckSlot.target, mluckSlot.runner.address, grossClaimable);
    let res = await tx.wait();
    expect(res.gasUsed).to.be.lessThan(30000000n);
    const balanceAfterClaim = await busd.balanceOf(mluckSlot.target);
    expect(balanceAfterClaim).to.equal(balanceBeforeClaim - grossClaimable);
  });

  it("should transfer in batches", async function () {
    let transferAmount = 100n;
    let tokenIds = [];
    let to = [];
    let recipient = ethers.Wallet.createRandom().address;
    const balanceBeforeTransfer = await mluckSlot.balanceOf(recipient);
    for (let i = 1n; i <= transferAmount; i++) {
      to.push(recipient);
      tokenIds.push(i);
    }

    expect(await mluckSlot.transferBatch(to, tokenIds)).to.be.ok;
    const balanceAfterTransfer = await mluckSlot.balanceOf(recipient);
    expect(balanceAfterTransfer).to.equal(balanceBeforeTransfer + transferAmount);

    const grossClaimable = await mluckSlot.grossClaimable(tokenIds);

    expect(grossClaimable).to.equal(0n);
  })

  it("should increase returns total", async function () {
    // TODO:  check if token owner is correct
    let amount = ethers.parseEther("100000");
    let returnsNext = 10000n;
    let tokenIds = [];
    for (let i = 1n; i <= 100n; i++) {
      tokenIds.push(i);
    }
    const grossClaimableBefore = await mluckSlot.grossClaimable(tokenIds);
    expect(grossClaimableBefore).to.equal(0n);
    expect(await busd.approve(mluckSlot.target, amount)).to.be.ok;
    expect(await mluckSlot.putReturns(returnsNext)).to.be.ok;
    const grossClaimableAfter = await mluckSlot.grossClaimable(tokenIds);
    expect(grossClaimableAfter).to.equal(returnsNext / 100n);
  });

  it("should return all tokens owned by wallet", async function () {
    let trx = await mluckSlot.ownedBy(mluckSlot.runner.address);
    expect(trx).to.be.an("array");
    let grossClaimable = await mluckSlot.grossClaimable(trx.map(x => x));
    expect(grossClaimable).to.be.equal(trx.length);
  });
})

