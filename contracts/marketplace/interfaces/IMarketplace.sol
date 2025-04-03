// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.22;

import { Promocode } from "../Promocode.sol";
import { Property } from "../Property.sol";
import { PropertyStatus } from "../PropertyStatus.sol";

interface IMarketplace {

    error InvalidSignatureLength(bytes sig, uint256 l);
    error InvalidSigner(bytes sig, address signer);
    error PromocodeExpired(bytes32 promocode);
    error PromocodeUsageLimitExceed(bytes32 promocode);
    error TokenTransferFailed(uint256 amount);
    error InvalidPromocodePercent(uint256 percent);

    function addProperty(Property memory _property) external;

    function removeProperty(address _property) external;

    function setPropertyStatus(address _property, PropertyStatus _status) external;

    function updatePriceAndFee(address _property, uint256 _price, uint256 _fee) external;

    function updatePrice(address _property, uint256 _price) external;

    function updateFee(address _property, uint256 _fee) external;

    // promo codes
    function setPromoCode(bytes32 _promoCode, Promocode memory _promocode) external;

    function deletePromoCode(bytes32 _promoCode) external;

    function getPromoCode(bytes32 _promoCode) external view returns (Promocode memory);

    // trade
    function buy(address _property, uint256[] memory _slots) external;
}
