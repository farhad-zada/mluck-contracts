// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

struct Promocode {
    uint256 discount;
    uint96 endTime;
    address owner;
    uint24 used;
}

contract Promo {

    mapping(address => bool) public promoValidators;
    mapping(bytes32 => Promocode) public promos;
    mapping(bytes32 => mapping(address => uint24)) public promoUsed;

    constructor() {
        promoValidators[msg.sender] = true;
    }

    function addPromo(
        bytes32 promoHash,
        uint256 discount,
        uint96 endTime,
        address owner
    ) public {
        promos[promoHash] = Promocode({discount: discount, endTime: endTime, owner: owner, used: 0});
    }

    function deletePromo(bytes32 promoHash) public {
        delete promos[promoHash];
    }

    function usePromo(bytes32 promoHash, bytes memory signature, address user) public {
        require(promos[promoHash].endTime >= block.timestamp, "Promo code has expired");
        require(promoUsed[promoHash][user] == 0, "Promo code already used by this user");

        // Recreate the message that was signed
        bytes32 messageHash = keccak256(abi.encodePacked(promoHash, user));
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));

        // Recover the signer's address
        address signer = recoverSigner(ethSignedMessageHash, signature);

        // Check if the signer is a valid promo validator
        require(promoValidators[signer], "Invalid signer");

        // Update the usage count
        promos[promoHash].used += 1;
        promoUsed[promoHash][user] = 1;
    }

    function recoverSigner(bytes32 ethSignedMessageHash, bytes memory signature) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);
        return ecrecover(ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "Invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        if (v < 27) {
            v += 27;
        }
    }
}