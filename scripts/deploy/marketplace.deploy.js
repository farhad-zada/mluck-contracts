const { ethers, run, network, upgrades } = require("hardhat");

const main = async () => {
    console.log("==========================================================================");
    let locker = "0x9b3909F3Fdb66F6E58c51767798869eDe2B2E4f4"
    let token = "0xc2132D05D31c914a87C6611C10748AEb04B58e8F"
    const Marketplace = await ethers.getContractFactory("Marketplace");
    const marketplace = await upgrades.deployProxy(Marketplace, [locker, token], {
        initializer: "initialize",
        kind: "uups"
    });

    if (network.name !== "hardhat") {
        await marketplace.deploymentTransaction().wait(5);
    }
    console.log("==========================================================================");
};


main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
