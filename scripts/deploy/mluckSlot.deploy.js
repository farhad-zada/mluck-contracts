const { ethers, run, network } = require("hardhat");

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
    console.log("- 1. Deployment");
    console.log("Deploying Mluck Slot contract 🚀");
    const constructorArguments = ["96B Nizami Ganjavi, Baku, Azerbaijan", "MLUCK", 2000n];
    const mluckSlot = await ethers.deployContract("MLUCKSlot", constructorArguments);

    console.log("Waiting for Mluck Slot deployment transaction to be mined ⏱️");
    await mluckSlot.deploymentTransaction().wait(10);
    console.log(`\x1b[32mMluck Slot deployed successfully at: \x1b[34m${mluckSlot.target} \x1b[0m`);
    if (network.name === "bsc") {
        console.log(`https://bscscan.com/address/${mluckSlot.target}`);
        await verify(mluckSlot.target, constructorArguments);
    } else if (network.name === "pol") {
        console.log(`https://polygonscan.com/address/${mluckSlot.target}`);
        await verify(mluckSlot.target, constructorArguments);
    }
    console.log("- 2. Minting");
    console.log("Minting 20 Mluck Slots 🚅");
    let slotIds = [];
    for (let i = 1n; i <= 4n; i++) {
        slotIds.push(i);
    }
    await mluckSlot.mintBatch(mluckSlot.runner.address, slotIds);
    const mintedSlots = await mluckSlot.ownedBy(mluckSlot.runner);
    console.log(`Slots Owned: ${mintedSlots.join(",")}`);
    console.log("==========================================================================");
    console.log("Hardhat deployment completed 🏁");
    console.log("Keep up the good work 🚀🚀🚀");
};

const verify = async (target, constructorArguments) => {
    console.log("\n\nVerifying contract on block explorer 🚦");
    await run("verify:verify", {
        address: target,
        constructorArguments
    });
    console.log("Mluck verified on etherscan ✅");
};

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
