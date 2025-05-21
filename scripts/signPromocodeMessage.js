const { ethers } = require("hardhat");

async function main() {
    const word = "BAKKR1";
    const promoHash = ethers.keccak256(ethers.AbiCoder.defaultAbiCoder().encode(["string"], [word]));
    const [signer] = await ethers.getSigners();

    const encoded = ethers.AbiCoder.defaultAbiCoder().encode(
        ["bytes32", "address"],
        [promoHash, "0xA5D9E8E2911D9E2A898f20223BbaEf69F564dFFA"]
    );
    const messageHash = ethers.keccak256(encoded); // this is the message hash

    const signature = await signer.signMessage(ethers.getBytes(messageHash)); // ✅ correctly sign the raw bytes

    console.log(`Promo Hash: ${promoHash}`);
    console.log(`Message Hash: ${messageHash}`);
    console.log(`Signature: ${signature}`);
    console.log(`Signer: ${signer.address}`);
}

main();
