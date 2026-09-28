// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.7.0
pragma solidity ^0.8.30;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Mock is ERC20 {
    constructor(address recipient) ERC20("MyToken", "MTK") payable {
        _mint(recipient, 10000 * 10 ** decimals());
    }
}
