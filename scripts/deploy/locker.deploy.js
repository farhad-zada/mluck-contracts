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
    console.log("Deploying Mluck Locker contract 🚀");
    const locker = await ethers.deployContract("Locker", []);

    console.log("Waiting for Mluck Locker deployment transaction to be mined ⏱️");
    await locker.deploymentTransaction().wait(10);
    console.log(`\x1b[32mMluck Slot deployed successfully at: \x1b[34m${locker.target} \x1b[0m`);
    if (network.name === "bsc") {
        console.log(`https://bscscan.com/address/${locker.target}`);
        await verify(locker.target);
    } else if (network.name === "pol") {
        console.log(`https://polygonscan.com/address/${locker.target}`);
        await verify(locker.target);
    }
    console.log("==========================================================================");
    console.log("Hardhat deployment completed 🏁");
    console.log("Keep up the good work 🚀🚀🚀");
};

const verify = async target => {
    console.log("\n\nVerifying contract on block explorer 🚦");
    await run("verify:verify", {
        address: target,
        constructorArguments: []
    });
    console.log("Mluck verified on etherscan ✅");
};

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
