const { ethers, run, network } = require("hardhat");

const main = async () => {

    console.log("Hardhat development starting ⚙️")
    console.log('==========================================================================');
    console.log('Deploying Mluck contract 🚀');
    const mluck = await ethers.deployContract("Mluck", [])
    console.log("Waiting for Mluck deployment transaction to be mined ⏱️");
    await mluck.deploymentTransaction().wait(10)
    console.log(`\x1b[32mMluck deployed successfully at: \x1b[34m${mluck.target} \x1b[0m`)
    if (network.name === 'bsc') {
        await verify(mluck.target)
    }
    console.log('==========================================================================');
    console.log("Hardhat deployment completed 🏁")
    console.log("Keep up the good work 🚀🚀🚀")
};

const verify = async (target) => {
    console.log("\n\nVerifying contract on block explorer 🚦")
    await run("verify:verify", {
        address: target,
        constructorArguments: [],
    });
    console.log("Mluck verified on etherscan ✅");
}

main().then(() => process.exit(0)).catch(error => {
    console.error(error);
    process.exit(1);
});