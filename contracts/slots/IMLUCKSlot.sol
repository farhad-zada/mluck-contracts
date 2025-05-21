// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.22;

import { IERC721 } from "@openzeppelin/contracts/interfaces/IERC721.sol";

interface IMLUCKSlot is IERC721 {
    /**
     * @dev Indicates that the token IDs array is empty.
     */
    error MLUCKSlotEmptyTokenIds();
    /**
     * @dev Indicates that the caller has insufficient BUSD or has not approved enough allowance to perform the operation.
     */
    error MLUCKSlotInvalidTokenIdsLength(uint256 length);
    /**
     * @dev Indicates that the token ID is invalid. This can happen when the token ID is not owned by the caller.
     * @param tokenId (uint256) The token ID that is invalid.
     */
    error MLUCKSlotInvalidTokenId(uint256 tokenId);

    /**
     * @dev See {ERC721-_sefeMint()}.
     */
    function mint(address to, uint256 items) external;


    /**
     * @dev Transfer multiple tokens to multiple addresses at once.
     * @param to The list of addresses to transfer to.
     * @param tokenIds the list of token IDs to transfer.
     */
    function transferBatch(address to, uint256[] memory tokenIds) external;

    /**
     * @dev Returns max supply. The maximum number of token, and the maximum token id
     * can be minted by this contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token IDs of the `_owner`
     * @param _owner the address that tokens belong to.
     */
    function ownedBy(address _owner) external view returns (uint256[] memory);


    function getOwnersList() external view returns (address[] memory);
}
