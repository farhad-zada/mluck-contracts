const { ethers, upgrase, upgrades } = require("hardhat");
const { expect } = require("chai");
const { parseEther } = ethers;

describe.only("MLCUK", function () {
  let Mluck;
  let mluck;
  let Encoder;
  let encoder;
  let deployer;
  let addr1;
  let addr2;
  let initialSupply = parseEther("100000000");

  beforeEach(async function () {
    Encoder = await ethers.getContractFactory("Encoder", {});
    encoder = await Encoder.deploy();
    Mluck = await ethers.getContractFactory("Mluck", {});
    [deployer, addr1, addr2] = await ethers.getSigners();
    mluck = await Mluck.deploy({});
  });

  async function setGovernor(governor, add) {
    const data = await encoder.governor(governor, add);
    await mluck.connect(deployer).makeRequest(2n, data);
    let requests = await mluck.requests();
    let request = requests[0];
    await mluck.approveRequest(request.id);
    let governors = await mluck.governors();
    return governors;
  }

  it("should have correct name and symbol", async function () {
    expect(await mluck.name()).to.equal("Mluck");
    expect(await mluck.symbol()).to.equal("MLUCK");
  });

  it("should have correct initial supply", async function () {
    expect(await mluck.totalSupply()).to.equal(initialSupply);
  });

  it("should have correct balance", async function () {
    expect(await mluck.balanceOf(deployer.address)).to.equal(initialSupply);
  });

  it("should transfer correctly", async function () {
    await mluck.transfer(addr1.address, parseEther("1000"));
    expect(await mluck.balanceOf(addr1.address)).to.equal(parseEther("1000"));
  });

  it("should approve correctly", async function () {
    await mluck.approve(addr1.address, parseEther("1000"));
    expect(await mluck.allowance(deployer.address, addr1.address)).to.equal(
      parseEther("1000")
    );
  });

  it("should transferFrom correctly", async function () {
    await mluck.approve(addr1.address, parseEther("1000"));
    await mluck
      .connect(addr1)
      .transferFrom(deployer.address, addr2.address, parseEther("1000"));
    expect(await mluck.balanceOf(addr2.address)).to.equal(parseEther("1000"));
  });

  it("should have governors correctly", async function () {
    const governors = await mluck.governors();
    expect(governors).to.have.lengthOf(1);
    expect(governors[0]).to.equal(deployer.address);
  });

  it("should have correct approveThreshold", async function () {
    expect(await mluck.approveThreshold()).to.equal(50n);
  });

  it("should add new governor correctly", async function () {
    const data = await encoder.governor(addr1, true);
    await mluck.connect(deployer).makeRequest(2n, data);
    const requests = await mluck.requests();
    let request = requests[0];
    await mluck.approveRequest(request.id);
    const governors = await mluck.governors();
    expect(governors).to.have.lengthOf(2);
    expect(governors[1]).to.equal(addr1.address);
  });

  it("should remove governor correctly", async function () {
    let governors = await setGovernor(addr1, true);
    expect(governors).to.have.lengthOf(2);
    expect(governors[1]).to.equal(addr1.address);

    const data2 = await encoder.governor(addr1, false);
    await mluck.connect(deployer).makeRequest(2n, data2);
    let requests = await mluck.requests();
    let request = requests[1];
    await mluck.connect(addr1).approveRequest(request.id);
    await mluck.approveRequest(request.id);
    governors = await mluck.governors();
    expect(governors).to.have.lengthOf(1);
    expect(governors[0]).to.equal(deployer.address);
  });

  it("should mint correctly", async function () {
    const governors = await setGovernor(addr1, true);
    const data = await encoder.mint(addr2, parseEther("1000"));
    await mluck.connect(addr1).makeRequest(0n, data);

    let requests = await mluck.requests();
    expect(await mluck.balanceOf(addr2.address)).to.equal(0n);
    await mluck
      .connect(deployer)
      .approveRequest(requests[requests.length - 1].id);
    await mluck.connect(addr1).approveRequest(requests[requests.length - 1].id);
    expect(await mluck.balanceOf(addr2.address)).to.equal(parseEther("1000"));
  });

  it("should allow only governor to make request", async function () {
    await expect(mluck.connect(addr1).makeRequest(0n, "0x")).to.be.revertedWith(
      "Mluck: not a governor"
    );
    await setGovernor(addr1, true);
    const data = await encoder.mint(addr2, parseEther("1000"));
    await expect(mluck.connect(addr1).makeRequest(0n, data)).to.be.not.reverted;
  });

  it("should revert incorrect data for request", async function () {
    await expect(
      mluck.connect(addr1).makeRequest(0n, "0x")
    ).to.be.not.revertedWithoutReason();
  });

  it("should allow only governor to approve request", async function () {
    await setGovernor(addr1, true);
    const data = await encoder.mint(addr2, parseEther("1000"));
    await mluck.connect(addr1).makeRequest(0n, data);
    let requests = await mluck.requests();
    await expect(
      mluck.connect(addr2).approveRequest(requests[requests.length - 1].id)
    ).to.be.revertedWith("Mluck: not a governor");
  });

  it("should revert incorrect request id for approval", async function () {
    await expect(
      mluck
        .connect(deployer)
        .approveRequest(
          "0xb10e2d527612073b26eecdfd717e6a320cf44b4afac2b0732d9fcbe2b7fa0123"
        )
    ).to.be.revertedWith("Mluck: invalid request id");
  });

  it("should not allow to approve request twice", async function () {
    await setGovernor(addr1, true);
    const data = await encoder.mint(addr2, parseEther("1000"));
    await mluck.connect(addr1).makeRequest(0n, data);
    let requests = await mluck.requests();
    await mluck
      .connect(deployer)
      .approveRequest(requests[requests.length - 1].id);
    await expect(
      mluck.connect(deployer).approveRequest(requests[requests.length - 1].id)
    ).to.be.revertedWith("Mluck: already voted");
  });

  it("should be able to set remnant correctly", async function () {
    const data = await encoder.remnant(parseEther("1"));
    await mluck.connect(deployer).makeRequest(4n, data);
    let requests = await mluck.requests();
    let request = requests[0];
    await mluck.approveRequest(request.id);
    expect(await mluck.remnant()).to.equal(parseEther("1"));
  });

  it("should be able to set approveThreshold correctly", async function () {
    const data = await encoder.threshold(60n);
    await mluck.connect(deployer).makeRequest(3n, data);
    let requests = await mluck.requests();
    let request = requests[0];
    await mluck.approveRequest(request.id);
    expect(await mluck.approveThreshold()).to.equal(60n);
  });

  it("should be able to withraw erc20 tokens", async function () {
    await mluck.transfer(mluck.target, parseEther("1000"));
    const data = await encoder.withdraw(
      mluck.target,
      deployer,
      parseEther("999.999999")
    );
    await mluck.connect(deployer).makeRequest(1n, data);
    let requests = await mluck.requests();
    let request = requests[0];
    await mluck.approveRequest(request.id);
    expect(await mluck.balanceOf(deployer.address)).to.equal(
      initialSupply - ethers.parseUnits("1", 12)
    );
  });


});
