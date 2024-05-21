// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library Encoder {
    function mint(
        address to,
        uint256 amount
    ) public pure returns (bytes memory data) {
        return abi.encode(to, amount);
    }

    function remnant(uint256 _remnant) public pure returns (bytes memory data) {
        return abi.encode(_remnant);
    }

    function withdraw(
        address token,
        address to,
        uint256 amount
    ) public pure returns (bytes memory data) {
        return abi.encode(token, to, amount);
    }

    function governor(
        address _governor,
        bool _add
    ) public pure returns (bytes memory data) {
        return abi.encode(_governor, _add);
    }

    function threshold(
        uint256 _threshold
    ) public pure returns (bytes memory data) {
        return abi.encode(_threshold);
    }
}
