const { ethers, run, network, upgrades } = require("hardhat");

const main = async () => {
    console.log('==========================================================================');
    let [deployer] = await ethers.getSigners();
    let MLUCKSlot = await ethers.getContractFactory("MLUCKSlot");
    let name = "Knightsbridge Residence CY2-1"
    let symbol = "MLUCK"
    let nonce = await deployer.getNonce();
    let contractAddress = ethers.getCreateAddress({from: deployer.address, nonce: nonce + 1});
    let baseURI = `https://chain.mluck.io/${contractAddress}/`
    console.log(baseURI);
    let bakKr1 = await upgrades.deployProxy(MLUCKSlot, [name, symbol, baseURI], {initializer: "initialize", kind: "uups"});
    if (network.name !== "hardhat") {
        await bakKr1.deploymentTransaction().wait(5);
    }

    console.log(`BAK-KR1 deployed at ${bakKr1.target}`)
    console.log('==========================================================================');
};


main().then(() => process.exit(0)).catch(error => {
    console.error(error);
    process.exit(1);
});