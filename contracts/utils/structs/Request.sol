// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../enums/RequestType.sol";

struct Request {
    bytes32 id;
    uint256 approved;
    RequestType requestType;
    bool executed;
    bytes data;
}
