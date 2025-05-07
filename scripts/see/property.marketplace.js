const { ethers } = require("hardhat");

const main = async () => {
    console.log("==========================================================================");
    let marketplace = await ethers.getContractAt("Marketplace", "0xb7eb310d2F3E6AF705ae7de6aEC69a51B00DaAc0");
    let property =  await marketplace.getProperty('0x5371627a1125655dec349F786236533569B65740');
    if (property.length === 0) {
        console.log("No property found");
        return;
    }
    console.log(`Property: ${property[0][0]}`);
    console.log(`Price: ${ethers.formatEther(property[0][1])} USDT`);
    console.log(`Fee: ${ethers.formatEther(property[0][2])} USDT`);
    console.log(`Status: ${property[1] == 0n ? "UNDEFINED" : property[1] == 1n ? "OPEN" : "CLOSE"}`);
    console.log(`Slots Available: ${property[2].length}`);
    console.log("==========================================================================");
};


main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
