// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.22;

import { IPancakeSwapRouter } from "./interfaces/IPancakeSwapRouter.sol";
import { IMarketplace } from "./interfaces/IMarketplace.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { IMLUCKSlot } from "../slots/IMLUCKSlot.sol";
import { Promocode } from "./Promocode.sol";
import { Property } from "./Property.sol";
import { PropertyStatus } from "./PropertyStatus.sol";
import { ILocker } from "./interfaces/ILocker.sol";

contract MLUCKMarketplace is Ownable, IMarketplace {

    IERC20 token;
    mapping(address signer => bool status) private s_signers;
    mapping(address propertyAddress => PropertyStatus status) private propertyStatus;
    mapping(address propertyAddress => Property) private s_properties;

    mapping(bytes32 code => Promocode) private s_promocodes;
    mapping(bytes32 code => mapping(address user => uint24 used)) private s_promoUsedByWallet;


    ILocker locker;

    constructor(address _locker, address _token) Ownable(msg.sender) {
        locker = ILocker(_locker);
        token = IERC20(_token);
    }

    function addProperty(Property memory _property) public onlyOwner {
        s_properties[_property.slotContract] = _property;
    }

    function removeProperty(address _slotContract) public onlyOwner {
        delete s_properties[_slotContract];
    }

    // this function sets the status of a property to be either tradable or untradable
    function setPropertyStatus(address _property, PropertyStatus _status) public onlyOwner {
        propertyStatus[_property] = _status;
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
    function buySlot(address _property, uint256[] memory _slots) public {
        Property memory property = s_properties[_property];
        uint256 cost = (_slots.length *(property.price + property.fee)); 
        // transfer tokens
        bool success = token.transferFrom(_msgSender(), address(this), cost);
        if (!success) revert TokenTransferFailed(cost);
        // transfer all the slots to buyer
        locker.massTransfer(_property, _msgSender(), _slots);
    }

    // promo codes
    function setPromoCode(bytes32 _promoCodeHash, Promocode memory _promocode) public onlyOwner {
        s_promocodes[_promoCodeHash] = _promocode;
    }

    function deletePromoCode(bytes32 _promoCode) public onlyOwner {
        delete s_promocodes[_promoCode];
    }

    function getPromoCode(bytes32 _promoCode) public view returns (Promocode memory) {
        return s_promocodes[_promoCode];
    }

    function setSigner(address signer, bool status) public onlyOwner {
        s_signers[signer] = status;
    }

    function validatePromocode(bytes32 promoHash, bytes memory signature, address user) public view returns (bool success) {
        Promocode memory promoCode = s_promocodes[promoHash];

        if (promoCode.expiresAt < block.timestamp) revert PromocodeExpired(promoHash);

        if (s_promoUsedByWallet[promoHash][user] == promoCode.maxUsePerWallet)
            revert PromocodeUsageLimitExceed(promoHash);

        // Recreate the message that was signed
        bytes32 messageHash = keccak256(abi.encodePacked(promoHash, user));
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));

        // Recover the signer's address
        address signer = recoverSigner(ethSignedMessageHash, signature);

        // Check if the signer is a valid promo validator
        if (!s_signers[signer]) revert InvalidSigner(signature, signer);

        return true;
    }

    function recoverSigner(bytes32 ethSignedMessageHash, bytes memory signature) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);
        return ecrecover(ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        if (sig.length != 65) revert InvalidSignatureLength(sig, sig.length);

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        if (v < 27) {
            v += 27;
        }
    }

    // locker
    function getLocker() public view returns (address) {
        return address(locker);
    }

    function setLocker(address _locker) public onlyOwner {
        locker = ILocker(_locker);
    }

    // withdraw
    function withdraw(IERC20 _token, uint256 amount) public onlyOwner {
        _token.transfer(_msgSender(), amount);
    }
}
