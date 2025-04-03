// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.22;

import { IMLUCKSlot } from "../../slots/IMLUCKSlot.sol";

interface ILocker {
    event Lock(address indexed property, address owner, uint256 slot);

    function setMarketplaceStatus(address marketplace, bool status) external;

    function getLocked(address property, uint256 slot) external view returns (bool);

    function getLockedAll(address property) external view returns (uint256[] memory);

    function transfer(address property, address to, uint256 slot) external;

    function massTransfer(address property, address to, uint256[] memory slots) external;

     function withdraw(address property, uint256[] memory slots) external;
}
