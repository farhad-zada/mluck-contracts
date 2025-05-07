const { ethers, run, network, upgrades } = require("hardhat");

const main = async () => {
    const Marketplace = await ethers.getContractFactory("Marketplace");
    const marketplace = await upgrades.deployProxy(Marketplace, [locker, token], {
        initializer: "initialize",
        kind: "uups"
    });

    if (network.name !== "hardhat") {
        await marketplace.deploymentTransaction().wait(5);
    }
    console.log("Done!");
};


main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
