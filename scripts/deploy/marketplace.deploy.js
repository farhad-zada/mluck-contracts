const { ethers, run, network, upgrades } = require("hardhat");

const locker = "0x7454b870798F34d410218A92c570dB32F3A51369";
const token = "0xD035c1571F64f06a1856cf5f017717dDf462bA2E"; // Polygon Self TBUSD: 0xD035c1571F64f06a1856cf5f017717dDf462bA2E

const main = async () => {
    console.log("Deploying...");

    console.log(`Locker: ${locker}`);
    console.log(`Token: ${token}`);
    const Marketplace = await ethers.getContractFactory("Marketplace");
    const marketplace = await upgrades.deployProxy(Marketplace, [locker, token], {
        initializer: "initialize",
        kind: "uups"
    });

    await marketplace.deploymentTransaction().wait(10);
    console.log(`\x1b[32mMluck MarketPlace deployed successfully at: \x1b[34m${marketplace.target} \x1b[0m`);
    if (network.name === "bsc") {
        console.log(`https://bscscan.com/address/${marketplace.target}`);
        await verify(marketplace.target);
    } else if (network.name === "pol") {
        console.log(`https://polygonscan.com/address/${marketplace.target}`);
        await verify(marketplace.target);
    }
    const lockerContract = await ethers.getContractAt("Locker", locker);
    await lockerContract.setMarketplaceStatus(marketplace.target, true);
    await marketplace.setSigner(marketplace.runner, true);
    console.log("Done!");
};

const verify = async target => {
    console.log("\n\nVerifying contract on block explorer 🚦");
    await run("verify:verify", {
        address: target,
        constructorArguments: [locker, token]
    });
    console.log("verified on block explorer ✅");
};

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
