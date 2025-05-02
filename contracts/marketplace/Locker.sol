// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.22;

import { ILocker } from "./interfaces/ILocker.sol";
import { IMLUCKSlot } from "../slots/IMLUCKSlot.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract Locker is ILocker, UUPSUpgradeable, IERC721Receiver, OwnableUpgradeable {
    mapping(address => bool status) private s_marketplace;

    modifier onlyMarketplace() {
        require(s_marketplace[msg.sender], "locker: only marketplace");
        _;
    }

    function initialize() public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) public returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
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

    function withdraw(address property, uint256[] memory slots) public onlyOwner {
        IMLUCKSlot slotApi = IMLUCKSlot(property);
        slotApi.transferBatch(_msgSender(), slots);
    }

    function getMarketplaceStatus(address marketplace) public view returns (bool) {
        return s_marketplace[marketplace];
    }
}
