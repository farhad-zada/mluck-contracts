# MLUCK

[![built-with openzeppelin](https://img.shields.io/badge/built%20with-OpenZeppelin-3677FF)](https://docs.openzeppelin.com/)

![Mluck Contract](./images/mluck.png)

## Description

This documentation provides step by step guide to integrate with MLUCK smart contracts.

### Getting Started

The smart contracts in this app are:

-   `MLUCKSlot`: This contract is the property smart contract that holds slots.
-   `Locker`: This contract is the locker that locks the slots to be put on sales. The idea is that many marketplace contracts can sell slots from this contract. So this gives us flexiblity to create many marketplace contracts that can sell slots from this contract.
-   `Marketplace`: This smart contract is the one that sells slots. Frontend interacts with this contract for buying slots.
-   `TBUSD`: This is a test BUSD token created by us for development purposes which can be used for test purchases.

### ABIs

To interact with smart contracts off-chain you first need is abis of the smart contracs.

### MLUCKSlot

This contract is `ERC721` NFT contract that holds slots.

Here is an overview of the functions of this contract:

-   `tokenURI(uint256 tokenId)` returns the uri of the token. This uri can be used to get info about the token.
-   `getOwnersList()` returns the list of owners of the slots.
-   `ownedBy(address owner)` returns the list of slots (e.g. `[1, 8, 19]`) owned by the owner.
-   `totalSupply()` returns the total number of slots that have been minted. This means that any token ID below this number is a valid token id.
-   `ownerOf(uint256 tokenId)` returns the owner of the token.

### Locker

In the frontend there is no interaction with this contract. This contract holds the slots that are intended to be put on sale. This gives us the flexiblity to create various marketplace contracts with different logics and features without changing the owner of slots that should be sold. This contract do not sell itslef.

### TBUSD (Test BUSD)

This is a test BUSD token created by us for development purposes which can be used for test purchases. This should be interpreted as BUSD token since the functionality is the same but this one do not hold any value.

### Marketplace

Here is the main contract that all the trade goes on. Consider that there would be multiple marketplace contracts that can sell slots in the future.

Let's break down the functions of this contract:

#### Get Property
FYI: a single marketplace contract can sell slots from multiple propertirs. 
To get the property info, the slots available for sale, and the sale status of slots you need to call the following get function:
```solidity
function getProperty(address property) external view returns (Property memory, PropertyStatus, uint256[] memory)
```


#### Buy Slots

To buy slots you need to call `buy(address property, uint256[] memory slotIds)` function. This function calculates the price of the slots and transfers the amount of BUSD from the buyer to the contract. If the transfer is successful only then it transfers slots to the buyer. To get the cost of purchase before buying you can call this function:

```solidity
function getCost(
        address _property, // The address of the property contract
        uint256[] memory _slotsCount // The count of slots would be purchased
   ) external view returns (uint256 cost)
```

To buy slots you don't need to any interaction with the backend.

#### Buy Slots With Promo

To buy slots using promo code you need to call:

```solidity
buyWithPromo(
        address _property,
        uint256[] memory slots,
        bytes32 promoHash,
        bytes memory signature
)
```

To call this contract you first need to acquire a signature signed from our backend then call the contract providing these info. To get the cost of purchase before buying you can call this function:

```solidity
function getCostUsingPromo(
        address _property, // The address of the property contract
        uint256 _slotsCount, // How many slots would be bought
        bytes32 _promoHash // the keccak256 hash of the promo code string
   ) external view returns (uint256 cost)
```

To buy slots using promo code you need to get the signature signed in our backend. See [this](https://github.com/farhad-zada/chain.mluck.io?tab=readme-ov-file#promocode-routes) for more info.


#### Promo Code

```solidity
   function getPromoCode(bytes32 _promoCode) public view returns (Promocode memory);
```
Returns the promo code info by giving the `keccak256` hash of the promo code string.
```solidity
   function getUserPromoUsage(bytes32 _promoHash) external view returns (uint256);
```
Returns how much the user have used the promo code.



### FAQ
1. How to get the properties list?
   - You need to get list of properties (addresses) from backend. See [this](https://github.com/farhad-zada/chain.mluck.io?tab=readme-ov-file#1-get-properties)

2. How to get if a property is on sale?
   - You need to call the `getProperty` function of the marketplace contract. This will return the property status and the slots available for sale.

3. How to get the slots available for sale?
   - You need to call the `getProperty` function of the marketplace contract. This will return the property status and the slots available for sale.
   
4. How to get the slots owned by a user?  
   - You need to call the `ownedBy` function of the MLUCKSlot contract. This will return the list of slots owned by the user.

5. How to get the owner of a slot?
   - You need to call the `ownerOf` function of the MLUCKSlot contract. This will return the owner of the slot.

6. How to get the total number of slots minted?
   - You need to call the `totalSupply` function of the MLUCKSlot contract. This will return the total number of slots minted.

7. How to get the uri of a slot?
   - You need to call the `tokenURI` function of the MLUCKSlot contract. This will return the uri of the slot.

8. How to get the list of owners of the slots?
   - You need to call the `getOwnersList` function of the MLUCKSlot contract. This will return the list of owners of the slots.

9. How to get the cost of a slot?
   - You can call the `getProperty` function that returns Property object which has `price`, `fee` fields that sum up to cost.

10. How to get the cost of a slot using promo code?
   - You can call the `getCostUsingPromo` function that returns the cost of a slot using promo code.
   
11. How to get the promo code info?
   - You can call the `getPromoCode` function that returns the promo code info.