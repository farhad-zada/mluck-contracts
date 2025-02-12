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
   * @dev BUSD (ERC20) address in Binance Smart Chain. BUSD is used for purchasing and
   * paying returns from investment.
   */
  address private s_busd;

  /**
   * @dev Total returns from this particular object being put into this contract which is
   * going to be claimed by owners of slots (MLUCKs)
   */
  uint256 private s_sharesTotal = 0;

  /**
   * @dev The price of a single slot in BUSD
   */
  uint256 private constant SLOT_PRICE = 100_000_000_000_000_000_000; // 100 BUSD

  /**
   * @dev Maximum number of slots can be mint and also the biggest slot ID (token ID).
   */
  uint256 private constant MAX_SUPPLY = 10000;

  /**
   * @dev Total number of tokens have been minted.
   */
  uint256 private s_totalSupply;

  /**
   * @dev Records claimed amount of the given token ID. So we use it to know how much
   * can a wallet claim now.
   */
  mapping(uint256 tokenId => uint256 claimed) public s_tokenClaims;

  /**
   * @dev Creates new contract for the object defined in the name specifically.
   * @param name The name of this object, e.g. "1234 Palm Jumeirah, Dubai, UAE"
   * @param symbol The symbol which is going to be SMLUCK for all
   * @param _busd The BUSD address for BSC
   */
  constructor(string memory name, string memory symbol, address _busd) ERC721(name, symbol) Ownable(msg.sender) {
    s_busd = _busd;
  }

  /**
   * @dev See {IMLUCKSlot-mint}
   */
  function mint(address to, uint256 tokenId) public {
    if (tokenId > MAX_SUPPLY || tokenId < 0) {
      revert MLUCKSlotTokenIdOutOfRange(tokenId);
    }
    takePayment(SLOT_PRICE);
    s_totalSupply = s_totalSupply + 1;
    _safeMint(to, tokenId);
  }

  /**
   * @dev See {IMLUCKSlot-mintBatch}
   */
  function mintBatch(address to, uint256[] memory tokenIds) public {
    uint256 totalCost = tokenIds.length * SLOT_PRICE;
    takePayment(totalCost);
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

  function takePayment(uint256 amount) private {
    bool success = IERC20(s_busd).transferFrom(_msgSender(), address(this), amount);
    if (!success) {
      revert MLUCKSlotInsufficientBUSD();
    }
  }

  /**
   * @dev See {IMLUCKSlot-claim}
   */
  function claim(uint256 tokenId) public {
    _requireOwned(tokenId);
    uint256 share = s_sharesTotal / MAX_SUPPLY;
    uint256 claimed = s_tokenClaims[tokenId];
    uint256 claimable = share - claimed;

    if (claimable == 0) {
      revert MLUCKSlotInsufficientClaim(claimable);
    }

    s_tokenClaims[tokenId] = share;
    IERC20(s_busd).transfer(msg.sender, claimable);
    emit Claim(msg.sender, tokenId, claimable);
  }

  /**
   * @dev See {IMLUCKSlot-claimAll}
   */
  function claimAll(uint256[] memory _tokenIds) public {
    uint256 share = s_sharesTotal / MAX_SUPPLY;
    uint256 totalClaimed = 0;
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      uint256 _tokenId = _tokenIds[i];
      if (this.ownerOf(_tokenId) != msg.sender) {
        revert MLUCKSlotInvalidTokenId(_tokenId);
      }
      totalClaimed = totalClaimed + s_tokenClaims[_tokenId];
      s_tokenClaims[_tokenId] = share;
    }

    uint256 grossClaim = (share * _tokenIds.length) - totalClaimed;

    if (grossClaim > 0) {
      bool success = IERC20(s_busd).transfer(msg.sender, grossClaim);
      if (!success) {
        revert MLUCKSlotInsufficientBUSD();
      }
    } else {
      revert MLUCKSlotInsufficientClaim(grossClaim);
    }
    emit ClaimAll(msg.sender, _tokenIds, grossClaim);
  }

  /**
   * @dev See {IMLUCKSlot-putReturns}
   */
  function putReturns(uint256 _value) public onlyOwner {
    bool success = IERC20(s_busd).transferFrom(msg.sender, address(this), _value);
    if (!success) {
      revert MLUCKSlotInsufficientBUSD();
    }
    s_sharesTotal = s_sharesTotal + _value;
    emit PutReturns(s_busd, _value);
  }

  /**
   * @dev See {IMLUCKSlot-transferBatch}
   */
  function transferBatch(address[] memory to, uint256[] memory tokenIds) public {
    if (to.length != tokenIds.length) {
      revert MLUCKSlotInvalidTokenIdsLength(tokenIds.length);
    }
    for (uint256 i = 0; i < tokenIds.length; i++) {
      _safeTransfer(msg.sender, to[i], tokenIds[i]);
    }
  }

  /**
   * @dev See {IMLUCKSlot-sharesTotal}
   */
  function sharesTotal() public view returns (uint256) {
    return s_sharesTotal;
  }

  /**
   * @dev See {IMLUCKSlot-claimableOfToken}
   */
  function claimableOfSlot(uint256 tokenId) public view returns (uint256) {
    uint256 share = s_sharesTotal / MAX_SUPPLY;
    uint256 claimed = s_tokenClaims[tokenId];
    return share - claimed;
  }

  /**
   * @dev See {IMLUCKSlot-sharePerToken}
   */
  function sharePerSlot() public view returns (uint256) {
    return s_sharesTotal / MAX_SUPPLY;
  }

  /**
   * @dev See {IMLUCKSlot-tokenClaims}
   */
  function tokenClaims(uint256[] memory _tokenIds) public view returns (uint256 totalClaimed) {
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      totalClaimed = totalClaimed + s_tokenClaims[i];
    }
  }

  /**
   * @dev See {IMLUCKSlot-grossClaimable}
   */
  function grossClaimable(uint256[] memory _tokenIds) public view returns (uint256 grossClaim) {
    uint256 share = s_sharesTotal / MAX_SUPPLY;
    uint256 totalClaimed = 0;
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      totalClaimed = totalClaimed + s_tokenClaims[_tokenIds[i]];
    }
    grossClaim = (share * _tokenIds.length) - totalClaimed;
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

  /**
   * @dev See {IMLUCKSlot-busdAddress}
   */
  function busdAddress() public view returns (address) {
    return s_busd;
  }

  /**
   * @dev Returns the slot price
   */
  function slotPrice() public pure returns (uint256) {
    return SLOT_PRICE;
  }
}
