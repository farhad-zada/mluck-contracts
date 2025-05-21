const { ethers, network, upgrades } = require("hardhat");

const main = async () => {
    console.log("==========================================================================");
    let Locker = await ethers.getContractFactory("Locker");
    const locker = await upgrades.deployProxy(Locker, [], { kind: "uups", initializer: "initialize" });

    if (network.name !== "hardhat") {
        await locker.deploymentTransaction().wait(5);
    }
    console.log(`Locker deployed at ${locker.target}`);
    console.log("==========================================================================");
};

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
