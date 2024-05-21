// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Request} from "./structs/Request.sol";
import {RequestType} from "./enums/RequestType.sol";

abstract contract Validatable {
    function validate(
        RequestType _requestType,
        bytes memory _data
    ) public pure {
        if (_requestType == RequestType.MINT) {
            _validateMintRequest(_data);
        } else if (_requestType == RequestType.WITHDRAW) {
            _validateWithdrawRequest(_data);
        } else if (_requestType == RequestType.GOVERNOR) {
            _validateGovernorRequest(_data);
        } else if (_requestType == RequestType.THRESHOLD) {
            _validateThresholdRequest(_data);
        } else if (_requestType == RequestType.REMNANT) {
            _validateRemnantRequest(_data);
        }
    }

    function _validateMintRequest(bytes memory _data) internal pure {
        abi.decode(_data, (address, uint256));
    }

    function _validateWithdrawRequest(bytes memory _data) internal pure {
        (address _token, address payable _to, uint256 _amount) = abi.decode(
            _data,
            (address, address, uint256)
        );
        require(_token != address(0), "Mluck: invalid token address");
        require(_to != address(0), "Mluck: invalid address");
        require(_amount > 0, "Mluck: invalid amount");
    }

    function _validateGovernorRequest(bytes memory _data) internal pure {
        (address _governor, ) = abi.decode(_data, (address, bool));
        require(_governor != address(0), "Mluck: invalid address");
    }

    function _validateThresholdRequest(bytes memory _data) internal pure {
        uint256 _threshold = abi.decode(_data, (uint256));
        require(
            _threshold > 0 && _threshold <= 100,
            "Mluck: invalid threshold"
        );
    }

    function _validateRemnantRequest(bytes memory _data) internal pure {
        uint256 _remnant = abi.decode(_data, (uint256));
        require(_remnant >= 0, "Mluck: invalid remnant");
    }
}
