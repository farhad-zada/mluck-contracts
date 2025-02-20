const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Promo", async function () {
    let signers;
    let deployer;
    let validator;

    this.beforeAll(async () => {
        // Get signers
        signers = await ethers.getSigners();
        deployer = signers[0];
        validator = signers[0]; // Assume this is the validator's address

        // Define the promo code and user address
        const promoCode = "SUMMER2023";
        const userAddress = "0x5B38Da6a701c568545dCfcB03FcB875f56beddC4";

        // Step 1: Hash the promo code
        const promoHash = ethers.keccak256(ethers.toUtf8Bytes(promoCode));
        console.log("Promo Hash:", promoHash);

        const abiCoder = new ethers.AbiCoder();
        // Step 2: Concatenate promoHash and userAddress
        const messageHash = ethers.keccak256(
            abiCoder.encode(
                ["bytes32", "address"],
                [promoHash, userAddress]
            )
        );
        console.log("Message Hash:", messageHash);

        // Step 3: Prefix the hash with "\x19Ethereum Signed Message:\n32"
        const ethSignedMessageHash = ethers.keccak256(
            ethers.solidityPacked(
                ["string", "bytes32"],
                ["\x19Ethereum Signed Message:\n32", messageHash]
            )
        );
        console.log("Ethereum Signed Message Hash:", ethSignedMessageHash);

        // Step 4: Sign the hash with the validator's private key
        const signature = await validator.signMessage(ethers.toUtf8Bytes(messageHash));
        console.log("Signature:", signature);

        // Step 5: Verify the signature (optional)
        const recoveredAddress = ethers.verifyMessage(ethers.toUtf8Bytes(messageHash), signature);
        console.log("Recovered Address:", recoveredAddress);
        console.log("Validator Address:", validator.address);

        // Ensure the recovered address matches the validator's address
        expect(recoveredAddress).to.equal(validator.address);
    });

    it("Should verify the signed message", async function () {
        // Your test case here
    });
});