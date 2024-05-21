// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {RequestType} from "../utils/enums/RequestType.sol";
import {Request} from "../utils/structs/Request.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMluck is IERC20 {
    function MAX_SUPPLY() external view returns (uint256);

    function makeRequest(
        RequestType _requestType,
        bytes calldata _data
    ) external;

    function approveRequest(bytes32 _id) external;

    function requests() external view returns (Request[] memory);

    function governors() external view returns (address[] memory);

    function remnant() external view returns (uint256);

    function approveThreshold() external view returns (uint256);

    function voted(bytes32 _id, address _governor) external view returns (bool);
}
