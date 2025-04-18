const { ethers, run, network } = require("hardhat");

const main = async () => {
    console.log("Deploying...");
    const constructorArguments = ["25A Nizami Ganjavi, Baku, Azerbaijan", "MLUCK", 5000n];
    const mluckSlot = await ethers.deployContract("MLUCKSlot", constructorArguments);
    await mluckSlot.deploymentTransaction().wait(10);
    console.log(`\x1b[32mMluck Slot deployed successfully at: \x1b[34m${mluckSlot.target} \x1b[0m`);
    if (network.name === "bsc") {
        console.log(`https://bscscan.com/address/${mluckSlot.target}`);
        await verify(mluckSlot.target, constructorArguments);
    } else if (network.name === "pol") {
        console.log(`https://polygonscan.com/address/${mluckSlot.target}`);
        await verify(mluckSlot.target, constructorArguments);
    }
    console.log("Done!");
};

const verify = async (target, constructorArguments) => {
    console.log("\n\nVerifying contract on block explorer 🚦");
    await run("verify:verify", {
        address: target,
        constructorArguments
    });
    console.log("verified on block explorer ✅");
};

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
