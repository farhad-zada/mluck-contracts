// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.22;
struct Promocode {
    uint256 percent;
    uint256 maxUse;
    uint24 maxUsePerWallet;
    uint256 expiresAt;
}