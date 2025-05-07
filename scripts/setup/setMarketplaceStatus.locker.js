const { ethers, run, network, upgrades } = require("hardhat");

const main = async () => {
    let locker = await ethers.getContractAt("Locker", "");
    let marketplace = ""

    await locker.setMarketplaceStatus(marketplace, true);
    console.log("Done!");
};


main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
