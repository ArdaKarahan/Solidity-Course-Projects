//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract UpgradableContract {
    uint private _value;

    event valueChanged(uint256 value);

    function store(uint256 value) public {
        _value = value;
        emit valueChanged(value);
    }

    function retrieve() public view returns(uint256) {
        return _value;
    }
}