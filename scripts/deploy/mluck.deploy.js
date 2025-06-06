const { ethers, run, network } = require("hardhat");

const main = async () => {
    console.log('==========================================================================');
    let [deployer] = await ethers.getSigners();
    let MLUCKSlot = await ethers.getContractFactory("MLUCKSlot");
    let name = "Knightsbridge Residence CY2-1"
    let symbol = "MLUCK"
    let nonce = await deployer.getNonce();
    let contractAddress = ethers.getCreateAddress({from: deployer.address, nonce});
    console.log(contractAddress);
    console.log('==========================================================================');
};


main().then(() => process.exit(0)).catch(error => {
    console.error(error);
    process.exit(1);
});