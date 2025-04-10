const { ethers, run, network, upgrades } = require("hardhat");

async function main() {
    const Marketplace = await ethers.getContractFactory("Marketplace");
    const locker = "0x7454b870798F34d410218A92c570dB32F3A51369";


    const upgradeRes = await upgrades.upgradeProxy(
        "0xdB73E33f0C8FB53886EA7729C9eCe7e983587D09",
        Marketplace,
    );
    console.log("Waiting for Mluck MarketPlace deployment transaction to be mined ⏱️");
}

void main();
