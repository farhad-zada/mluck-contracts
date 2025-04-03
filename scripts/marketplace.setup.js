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
     * 
     * Polygon Test:
        - BUSD:         0xD035c1571F64f06a1856cf5f017717dDf462bA2E
        - MLUCK Slot:   0xC9B6F0d780AdC12125B18d45898Cde4764A75ce9
        - Locker:       0xC36ee58BB9D58D9723bc3Ac7Be724576F01CA7a0
        - MarketPLace:  0x89c5518905694D1f0254c0421E90Dc309BC323eb
     */

    console.log("Hardhat development starting ⚙️");
    console.log("==========================================================================");
    const busd = await ethers.getContractAt("BUSD", "0xD035c1571F64f06a1856cf5f017717dDf462bA2E");
    const mluckSlot = await ethers.getContractAt("MLUCKSlot", "0xC9B6F0d780AdC12125B18d45898Cde4764A75ce9");
    const locker = await ethers.getContractAt("0xC36ee58BB9D58D9723bc3Ac7Be724576F01CA7a0");
    const mp = await ethers.getContractAt("Marketplace", "0x89c5518905694D1f0254c0421E90Dc309BC323eb");
    console.log("Locker: " + (await mp.getLocker()));
    console.log("BUSD balance: " + (await busd.balanceOf(busd.runner)));
    
    console.log("==========================================================================");
    console.log("Hardhat deployment completed 🏁");
    console.log("Keep up the good work 🚀🚀🚀");
};

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
