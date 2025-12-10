// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyERC20 is ERC20 {
    constructor() ERC20("MyERC20", "MERC20") {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }
    function mint(address to,uint256 amount) public {
        _mint(to, amount * 10 ** decimals());
    }
}