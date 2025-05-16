const { ethers } = require("hardhat");

const main = async () => {
    console.log("==========================================================================");
    let marketplace = await ethers.getContractAt("Marketplace", "0xb7eb310d2F3E6AF705ae7de6aEC69a51B00DaAc0");
    let promoHash = "0x82fea8ef8fa2df656a86c35e01d1894b86123f5d1a38359d7faf83c3215d75b0";
    let args = [
        9900n, // discount percent
        10n, // fee
        10n,
        (Math.ceil(Date.now() / 1000) + 2 * 24 * 60 * 60).toString(),
    ]
    await marketplace.setPromoCode(promoHash, args);
    console.log("==========================================================================");
};


main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
