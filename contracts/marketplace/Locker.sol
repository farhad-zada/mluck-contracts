// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.22;

import { ILocker } from "./interfaces/ILocker.sol";
import {IMLUCKSlot} from "../slots/IMLUCKSlot.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Locker is ILocker, Ownable(msg.sender) {

    mapping(address => bool status) private s_marketplace;

    modifier onlyMarketplace {
        require(s_marketplace[msg.sender], "locker: only marketplace");
        _;
    }

    function setMarketplaceStatus(address marketplace, bool status) public onlyOwner {
        s_marketplace[marketplace] = status;
    }

    function getLocked(address property, uint256 slot) public view returns (bool) {
        return IMLUCKSlot(property).ownerOf(slot) == address(this);
    }

    function getLockedAll(address property) public view returns (uint256[] memory) {
        return IMLUCKSlot(property).ownedBy(address(this));
    }

    function transfer(address property, address to, uint256 slot) public onlyMarketplace {
        IMLUCKSlot slotApi = IMLUCKSlot(property);
        slotApi.safeTransferFrom(address(this), to, slot);
    }

    function massTransfer(address property, address to, uint256[] memory slots) public onlyMarketplace {
        IMLUCKSlot slotApi = IMLUCKSlot(property);
        slotApi.transferBatch(to, slots);
    }

    function lock(address property, uint256[] memory slots) public {
        IMLUCKSlot slotApi = IMLUCKSlot(property);
        for (uint256 i = 0; i < slots.length; i++) {
            slotApi.safeTransferFrom(_msgSender(), address(this), slots[i]);
            emit Lock(property, _msgSender(), slots[i]);
        }
    }

    function withdraw(address property, uint256[] memory slots) public onlyOwner {
        IMLUCKSlot slotApi = IMLUCKSlot(property);
        slotApi.transferBatch(_msgSender(), slots);
    }
}