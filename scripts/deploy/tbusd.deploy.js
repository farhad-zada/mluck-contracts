const { ethers, run, network } = require("hardhat");

const main = async () => {

    console.log("Hardhat development starting ⚙️")
    console.log('==========================================================================');
    console.log('Deploying BUSD contract 🚀');
    const busd = await ethers.deployContract("BUSD", [])
    console.log("Waiting for BUSD deployment transaction to be mined ⏱️");
    await busd.deploymentTransaction().wait(10)
    console.log(`\x1b[32mMluck deployed successfully at: \x1b[34m${busd.target} \x1b[0m`)
    console.log(`https://bscscan.com/address/${busd.target}`);
    if (network.name === 'bsc') {
        await verify(busd.target)
    }
    const balance = await busd.balanceOf(busd.runner.address);
    console.log(`Deployer BUSD balance: ${ethers.formatEther(balance)}`);
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
    console.log("BUSD verified on etherscan ✅");
}

main().then(() => process.exit(0)).catch(error => {
    console.error(error);
    process.exit(1);
});