const { ethers, run, network, upgrades } = require("hardhat");

const locker = "0x7454b870798F34d410218A92c570dB32F3A51369";
const token = "0xD035c1571F64f06a1856cf5f017717dDf462bA2E"; // Polygon Self TBUSD: 0xD035c1571F64f06a1856cf5f017717dDf462bA2E

const main = async () => {
    /**
     * Deploy Test BUSD
     * Deploy MLUCK Slot
     * Mint Slots on MLUCK
     *
     * Deploy Locker
     * Deploy Marketplace
     * Set up MarketPlace to use Locker
     * Set up trade
     * Set up secondary wallet (send BNB & send TBUSD)
     * With Secondary Wallet:
     *  Buy 5 Slots
     *  Buy 2 More
     */

    console.log("Hardhat development starting ⚙️");
    console.log("==========================================================================");
    console.log("Deploying Mluck MarketPlace contract 🚀");

    console.log(`Locker: ${locker}`);
    console.log(`Token: ${token}`);
    const Marketplace = await ethers.getContractFactory("Marketplace");
    const marketplace = await upgrades.deployProxy(Marketplace, [locker, token], {
        initializer: "initialize",
        kind: "uups"
    });

    console.log("Waiting for Mluck MarketPlace deployment transaction to be mined ⏱️");
    await marketplace.deploymentTransaction().wait(10);
    console.log(`\x1b[32mMluck MarketPlace deployed successfully at: \x1b[34m${marketplace.target} \x1b[0m`);
    if (network.name === "bsc") {
        console.log(`https://bscscan.com/address/${marketplace.target}`);
        await verify(marketplace.target);
    } else if (network.name === "pol") {
        console.log(`https://polygonscan.com/address/${marketplace.target}`);
        await verify(marketplace.target);
    }
    console.log("Setting up Locker...");
    const lockerContract = await ethers.getContractAt("Locker", locker);
    await lockerContract.setMarketplaceStatus(marketplace.target, true);
    console.log("Done!");
    console.log("Setting up promocode signer status!");
    await marketplace.setSigner(marketplace.runner, true);
    console.log("Done!");
    console.log("==========================================================================");
    console.log("Hardhat deployment completed 🏁");
    console.log("Keep up the good work 🚀🚀🚀");
};

const verify = async target => {
    console.log("\n\nVerifying contract on block explorer 🚦");
    await run("verify:verify", {
        address: target,
        constructorArguments: [locker, token]
    });
    console.log("Mluck verified on etherscan ✅");
};

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
