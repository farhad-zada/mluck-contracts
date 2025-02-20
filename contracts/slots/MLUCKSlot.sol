// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import { IMLUCKSlot } from "./IMLUCKSlot.sol";

// TODO:
// 1. add set option for baseURL
contract MLUCKSlot is ERC721, Ownable, IMLUCKSlot {
    /**
     * @dev Maximum number of slots can be mint and also the biggest slot ID (token ID).
     */
    uint256 private constant MAX_SUPPLY = 10000;

    /**
     * @dev Total number of tokens have been minted.
     */
    uint256 private s_totalSupply;

    /**
     * @dev Creates new contract for the object defined in the name specifically.
     * @param name The name of this object, e.g. "1234 Palm Jumeirah, Dubai, UAE"
     * @param symbol The symbol which is going to be SMLUCK for all
     */
    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) {}

    /**
     * @dev See {IMLUCKSlot-mint}
     */
    function mint(address to, uint256 tokenId) public onlyOwner {
        if (tokenId > MAX_SUPPLY || tokenId < 0) {
            revert MLUCKSlotTokenIdOutOfRange(tokenId);
        }
        s_totalSupply = s_totalSupply + 1;
        _safeMint(to, tokenId);
    }

    /**
     * 
     * @dev See {IMLUCKSlot-mintBatch}
     */
    function mintBatch(address to, uint256[] memory tokenIds) public {
        if (tokenIds.length == 0) {
            revert MLUCKSlotEmptyTokenIds();
        }
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (tokenIds[i] > MAX_SUPPLY || tokenIds[i] < 0) {
                revert MLUCKSlotTokenIdOutOfRange(tokenIds[i]);
            }
            _safeMint(to, tokenIds[i]);
        }
        s_totalSupply = s_totalSupply + tokenIds.length;
    }

    /**
     * @dev See {IMLUCKSlot-transferBatch}
     */
    function transferBatch(address to, uint256[] memory tokenIds) public {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _safeTransfer(msg.sender, to, tokenIds[i]);
        }
    }

    /**
     * @dev See {IMLUCKSlot-maxSupply}
     */
    function maxSupply() public pure returns (uint256) {
        return MAX_SUPPLY;
    }

    /**
     * @dev See {IMLUCKSlot-totalSupply}
     */
    function totalSupply() public view returns (uint256) {
        return s_totalSupply;
    }

    /**
     * @dev See {IMLUCKSlot-ownedBy}
     */
    function ownedBy(address _owner) public view returns (uint256[] memory) {
        uint256 balance = this.balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](balance);
        uint256 index = 0;
        for (uint256 tokenId = 1; tokenId < MAX_SUPPLY; tokenId++) {
            if (_ownerOf(tokenId) == _owner) {
                tokenIds[index] = tokenId;
                index = index + 1;
            }
        }
        return tokenIds;
    }
}
