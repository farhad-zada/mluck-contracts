const { ethers, run, network, upgrades } = require("hardhat");

const main = async () => {
    console.log("==========================================================================");
    let locker = await ethers.getContractAt("Locker", "0x9b3909F3Fdb66F6E58c51767798869eDe2B2E4f4");
    let marketplace = "0xb7eb310d2F3E6AF705ae7de6aEC69a51B00DaAc0"

    let status = await locker.getMarketplaceStatus(marketplace);
    console.log(`Marketplace status is: ${status}`);
    console.log("==========================================================================");
};


main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
