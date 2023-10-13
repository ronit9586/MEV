// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract XENDoge is ERC20 {
    constructor() ERC20("XENDoge", "XENDoge") {
        _mint(msg.sender, 1000000000000000000000000000 * (10 ** 18));
    }
}