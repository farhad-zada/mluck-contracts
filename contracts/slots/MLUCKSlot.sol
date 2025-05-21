// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract MLUCKSlot is ERC721Upgradeable, OwnableUpgradeable, UUPSUpgradeable {
    /**
     * @dev Total number of tokens have been minted.
     */
    uint256 private s_totalSupply;

    string public s_baseURI;

    /**
     * @dev Creates new contract for the object defined in the name specifically.
     * @param name_ The name of this object, e.g. "1234 Palm Jumeirah, Dubai, UAE"
     * @param symbol_ The symbol which is going to be SMLUCK for all
     */
    function initialize(
        string memory name_,
        string memory symbol_,
        string memory baseURI_
    ) public initializer {
        __Ownable_init(msg.sender);
        __ERC721_init(name_, symbol_);
        s_baseURI = baseURI_;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    /**
     * @dev See {IMLUCKSlot-mint}
     */
    function mint(address to, uint256 items) public onlyOwner {
        uint256 nextTokenId = s_totalSupply + 1;
        for (nextTokenId; nextTokenId <= s_totalSupply + items; nextTokenId++) {
            _safeMint(to, nextTokenId);
        }

        s_totalSupply = s_totalSupply + items;
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
        for (uint256 tokenId = 1; tokenId <= this.totalSupply(); tokenId++) {
            if (_ownerOf(tokenId) == _owner) {
                tokenIds[index] = tokenId;
                index = index + 1;
            }
        }
        return tokenIds;
    }

    function getOwnersList() public view returns (address[] memory) {
        address[] memory holders = new address[](s_totalSupply);

        for (uint256 slotId = 1; slotId <= s_totalSupply; slotId++) {
            holders[slotId - 1] = _ownerOf(slotId);
        }

        return holders;
    }

    function _baseURI() internal view override returns (string memory) {
        return s_baseURI;
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        s_baseURI = baseURI_;
    }
}
