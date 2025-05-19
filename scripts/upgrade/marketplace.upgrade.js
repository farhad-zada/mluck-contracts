const { ethers, run, network, upgrades } = require("hardhat");

const main = async () => {
    console.log("==========================================================================");
    const Marketplace = await ethers.getContractFactory("Marketplace");
    const marketplace = await upgrades.upgradeProxy("0xb7eb310d2F3E6AF705ae7de6aEC69a51B00DaAc0", Marketplace);
    console.log("Marketplace upgraded");
    console.log("==========================================================================");
};


main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
