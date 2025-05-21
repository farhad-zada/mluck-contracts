const { ethers } = require("hardhat");

const main = async () => {
    console.log("==========================================================================");
    let toEth = ethers.parseEther;
    let marketplace = await ethers.getContractAt("Marketplace", "0xb7eb310d2F3E6AF705ae7de6aEC69a51B00DaAc0");

    let property = "0x5371627a1125655dec349F786236533569B65740";
    await marketplace.setPropertyStatus(property, 1n);
    console.log("==========================================================================");
};

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
