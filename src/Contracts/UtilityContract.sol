// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./IUtilityContract.sol";

contract UtilityContract is IUtilityContract {
    error AlreadyInitialized();

    modifier notInitialized() {
        require(!initialized, AlreadyInitialized());
        _;
    }

    bool private initialized;

    function initialize(bytes memory) external notInitialized returns (bool) {}
}

