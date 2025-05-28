// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract PurchaseLimitable is AccessControl {
    uint256 public purchaseLimit;

    function setPurchaseLimit(uint256 newLimit) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        purchaseLimit = newLimit;
    }

    modifier isUnderPurchaseLimit(address to, uint256 amount, ERC721 token) {
        if (to != address(0)) {
            require(token.balanceOf(to) + amount <= purchaseLimit, "Purchase limit exceeded");
        }
        _;
    }
}
