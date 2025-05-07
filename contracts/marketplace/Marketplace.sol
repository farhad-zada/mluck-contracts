// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.22;

import { IPancakeSwapRouter } from "./interfaces/IPancakeSwapRouter.sol";
import { IMarketplace } from "./interfaces/IMarketplace.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { IMLUCKSlot } from "../slots/IMLUCKSlot.sol";
import { Promocode } from "./Promocode.sol";
import { Property } from "./Property.sol";
import { PropertyStatus } from "./PropertyStatus.sol";
import { ILocker } from "./interfaces/ILocker.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract Marketplace is OwnableUpgradeable, UUPSUpgradeable, IMarketplace {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    IERC20 token;
    mapping(address signer => bool status) private s_signers;
    mapping(address propertyAddress => PropertyStatus status) private propertyStatus;
    mapping(address propertyAddress => Property) private s_properties;

    mapping(bytes32 code => Promocode) private s_promocodes;
    mapping(bytes32 code => uint256 used) public s_promoused;
    mapping(bytes32 code => mapping(address user => uint256 used)) private s_promoUsedByWallet;

    ILocker locker;

    modifier tradableProperty(address _property) {
        require(propertyStatus[_property] == PropertyStatus.OPEN, "property is not open to trade!");
        _;
    }

    function initialize(address _locker, address _token) public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        locker = ILocker(_locker);
        token = IERC20(_token);
    }

    function _authorizeUpgrade(address newImplementation) internal onlyOwner override {}

    // property funcs
    function addProperty(Property memory _property) public onlyOwner {
        s_properties[_property.slotContract] = _property;
    }

    function removeProperty(address _slotContract) public onlyOwner {
        delete s_properties[_slotContract];
    }

    function getProperty(address property) public view returns (Property memory, PropertyStatus, uint256[] memory) {
        Property memory m_property = s_properties[property];
        uint256[] memory onSale = locker.getLockedAll(m_property.slotContract);
        PropertyStatus m_propertyStatus = propertyStatus[m_property.slotContract];
        return (m_property, m_propertyStatus, onSale);
    }

    function setPropertyStatus(address _property, PropertyStatus _status) public onlyOwner {
        propertyStatus[_property] = _status;
    }

    function getPropertyStatus(address _property) public view returns (PropertyStatus) {
        return propertyStatus[_property];
    }

    function updatePriceAndFee(address _property, uint256 _price, uint256 _fee) public onlyOwner {
        s_properties[_property].price = _price;
        s_properties[_property].fee = _fee;
    }

    function updatePrice(address _property, uint256 _price) public onlyOwner {
        s_properties[_property].price = _price;
    }

    function updateFee(address _property, uint256 _fee) public onlyOwner {
        s_properties[_property].fee = _fee;
    }

    // trade
    function buy(address _property, uint256[] memory _slots) public tradableProperty(_property) {
        Property memory m_property = s_properties[_property];
        require(m_property.slotContract != address(0), "invalid property");
        uint256 _cost = (_slots.length * (m_property.price + m_property.fee));
        // transfer tokens
        _buy(_property, _slots, _cost);
    }

    function buyWithPromo(
        address _property,
        uint256[] memory _slots,
        bytes32 _promoHash,
        bytes memory signature
    ) public tradableProperty(_property) {
        address msgSender = _msgSender();
        Promocode memory m_promocode = s_promocodes[_promoHash];
        Property memory m_property = s_properties[_property];
        require(m_property.slotContract != address(0), "invalid property");
        validatePromocode(_promoHash, signature, msgSender, m_promocode);
        (uint256 _cost, uint256 _promoUsage) = _costUsingPromo(m_promocode, m_property, _slots.length, _promoHash);
        _updatePromoUsage(_promoHash, msgSender, _promoUsage);
        // transfer tokens
        _buy(_property, _slots, _cost);
    }

    function _buy(address _property, uint256[] memory _slots, uint256 _cost) internal {
        bool success = token.transferFrom(_msgSender(), address(this), _cost);
        if (!success) revert TokenTransferFailed(_cost);
        locker.massTransfer(_property, _msgSender(), _slots);
    }

    function _updatePromoUsage(bytes32 _promoHash, address _account, uint256 _usage) internal {
        s_promoUsedByWallet[_promoHash][_account] = _usage;
    }

    function _costUsingPromo(
        Promocode memory promocode,
        Property memory property,
        uint256 _slotsCount,
        bytes32 _promoHash
    ) internal view returns (uint256 cost, uint256 promoUsage) {
        address msgSender = _msgSender();
        uint256 userUsedPromocodeCount = s_promoUsedByWallet[_promoHash][msgSender];
        uint256 maxDiscountedItemsCount = promocode.maxUsePerWallet - userUsedPromocodeCount;
        uint256 discountedItemsCount;
        if (_slotsCount > maxDiscountedItemsCount) {
            discountedItemsCount = maxDiscountedItemsCount;
        } else {
            discountedItemsCount = _slotsCount;
        }
        promoUsage = userUsedPromocodeCount + discountedItemsCount;
        // percent should be like:
        // 100_00 for 100.0%
        // 1 for 0.01%
        uint256 discount = ((property.price * promocode.percent) / 10000) * discountedItemsCount;
        cost = (_slotsCount * (property.price + property.fee)) - discount;
    }

    function getCost(address _property, uint256 _slotsCount) public view returns (uint256 cost) {
        Property memory property = s_properties[_property];
        cost = (_slotsCount * (property.price + property.fee));
    }

    function getCostUsingPromo(
        address _property,
        uint256 _slotsCount,
        bytes32 _promoHash
    ) public view returns (uint256 cost) {
        Promocode memory m_promocode = s_promocodes[_promoHash];
        Property memory m_property = s_properties[_property];
        (cost, ) = _costUsingPromo(m_promocode, m_property, _slotsCount, _promoHash);
    }

    // promo codes
    function setPromoCode(bytes32 _promoCodeHash, Promocode memory _promocode) public onlyOwner {
        if (_promocode.percent < 1 || _promocode.percent > 10000) {
            revert InvalidPromocodePercent(_promocode.percent);
        }
        s_promocodes[_promoCodeHash] = _promocode;
    }

    function validatePromocode(
        bytes32 promoHash,
        bytes memory signature,
        address user,
        Promocode memory promoCode
    ) public view {
        if (promoCode.expiresAt < block.timestamp) revert PromocodeExpired(promoHash);
        require(s_promoUsedByWallet[promoHash][user] < promoCode.maxUsePerWallet, "promo usage exceeded limit");
        address signer = keccak256(abi.encode(promoHash, user)).toEthSignedMessageHash().recover(signature);
        if (!s_signers[signer]) revert InvalidSigner(signature, signer);
    }

    function deletePromoCode(bytes32 _promoCode) public onlyOwner {
        delete s_promocodes[_promoCode];
    }

    function getPromoCode(bytes32 _promoCode) public view returns (Promocode memory) {
        return s_promocodes[_promoCode];
    }

    function isPromoExpired(bytes32 _hash) public view returns (bool) {
        return s_promocodes[_hash].expiresAt < block.timestamp;
    }

    function setSigner(address signer, bool status) public onlyOwner {
        s_signers[signer] = status;
    }

    function getSigner(address signer) public view returns (bool) {
        return s_signers[signer];
    }

    function getUserPromoUsage(bytes32 _promoHash) public view returns (uint256) {
        return s_promoUsedByWallet[_promoHash][msg.sender];
    }

    // locker
    function getLocker() public view returns (address) {
        return address(locker);
    }

    function setLocker(address _locker) public onlyOwner {
        locker = ILocker(_locker);
    }

    function getToken() public view returns (address) {
        return address(token);
    }

     function setToken(address token_) public onlyOwner {
        token = IERC20(token_);
    }

    // withdraw
    function withdraw(IERC20 _token, uint256 amount) public onlyOwner {
        _token.transfer(_msgSender(), amount);
    }
}
