// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.22;

import { IERC721 } from "@openzeppelin/contracts/interfaces/IERC721.sol";

interface IMLUCKSlot is IERC721 {
  /**
   * @dev Inticates that the token ID (`tokenId`) is out of range, i.e. either less than 1 or greater than MAX_SUPPLY.
   * @param tokenId (uint256) The token ID that is out of range.
   */
  error MLUCKSlotTokenIdOutOfRange(uint256 tokenId);
  /**
   * @dev Indicates that the token IDs array is empty.
   */
  error MLUCKSlotEmptyTokenIds();
  /**
   * @dev Indicates that the caller has insufficient BUSD or has not approved enough allowance to perform the operation.
   */
  error MLUCKSlotInsufficientBUSD();
  /**
   * @dev Indicates that the caller has insufficient claimable amount (means zero since uint256 cannot be less than zero)
   * to claim the token.
   * @param claimable (uint256) The claimable amount that owner of slot/NFT/token or slots/NFTs/tokens
   * claim for holding that token.
   */
  error MLUCKSlotInsufficientClaim(uint256 claimable);
  /**
   * @dev Indicates that the token IDs array length is invalid.This can happen when it is expected to meet certain
   * conditions but it does not. Such as when the length of the token IDs array is expected to be equal to
   * balanceOf(msg.sender) but it is not.
   * @param length (uint256) The length of the token IDs array.
   */
  error MLUCKSlotInvalidTokenIdsLength(uint256 length);
  /**
   * @dev Indicates that the token ID is invalid. This can happen when the token ID is not owned by the caller.
   * @param tokenId (uint256) The token ID that is invalid.
   */
  error MLUCKSlotInvalidTokenId(uint256 tokenId);

  event Claim(address claimer, uint256 tokenId, uint256 value);
  event ClaimAll(address claimer, uint256[] tokenIds, uint256 values);
  event PutReturns(address indexed busd, uint256 value);

  /**
   * @dev See {ERC721-_sefeMint()}.
   */
  function mint(address to, uint256 tokenId) external;

  /**
   * @dev Mints multiple tokens to the given addresses.
   */
  function mintBatch(address to, uint256[] memory tokenIds) external;

  /**
   * @dev Holders of slots uses this to claim the returns of the slot.
   */
  function claim(uint256 tokenId) external;

  /**
   * @dev Holders of slots uses this to claim the returns of all the slots they hold.
   */
  function claimAll(uint256[] memory _tokenIds) external;

  /**
   * @dev Owner(s) of the contract uses this to put the total returns into the contract.
   * Total returns are the returns from the real estate investment. And it is going to be
   * put into this contract so people can claim their share of the returns.
   * @param _totalReturns is the total returns to be put into the contract
   */
  function putReturns(uint256 _totalReturns) external;

  /**
   * @dev Transfer multiple tokens to multiple addresses at once.
   * @param to The list of addresses to transfer to.
   * @param tokenIds the list of token IDs to transfer.
   */
  function transferBatch(address[] memory to, uint256[] memory tokenIds) external;

  /**
   * @dev Returns the total shares (simply the total returns put to this contract from
   * the investment by owner) of the slots.
   */
  function sharesTotal() external view returns (uint256);

  /**
   * @dev Returns the claimable amount of the given token ID.
   * @param tokenId is the token ID to get the claimable amount.
   */
  function claimableOfSlot(uint256 tokenId) external view returns (uint256);

  /**
   * @dev Returns the share per token. This is the total shares divided by the max supply.
   */
  function sharePerSlot() external view returns (uint256);

  /**
   * @dev Returns the total claimed amount of the given token IDs.
   * @param _tokenIds is the list of token IDs to get the total claimed amount.
   */
  function tokenClaims(uint256[] memory _tokenIds) external view returns (uint256 totalClaimed);

  /**
   * @dev Returns the gross claimable amount for given token IDs.
   * @param _tokenIds is the list of token IDs to get the gross claimable amount for.
   */
  function grossClaimable(uint256[] memory _tokenIds) external view returns (uint256 grossClaim);

  /**
   * @dev Returns max supply. The maximum number of token, and the maximum token id
   * can be minted by this contract.
   */
  function maxSupply() external pure returns (uint256);
  
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

  /**
   * @dev Returns the address of BUSD token on BSC
   */
  function busdAddress() external view returns (address);
}
