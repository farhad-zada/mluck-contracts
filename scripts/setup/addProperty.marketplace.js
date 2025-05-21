const { ethers } = require("hardhat");

const main = async () => {
    console.log("==========================================================================");
    let toEth = ethers.parseEther;
    let marketplace = await ethers.getContractAt("Marketplace", "0xb7eb310d2F3E6AF705ae7de6aEC69a51B00DaAc0");
    let args = [
        "0x386C97AAfCE25c24B0eD2C171A80b5f6b083037A", // property
        toEth("100"), // price
        0n, // fee
    ]
    await marketplace.addProperty(args);
    console.log("==========================================================================");
};


main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
