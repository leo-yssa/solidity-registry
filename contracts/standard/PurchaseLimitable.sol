// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./StdErrors.sol";

abstract contract PurchaseLimitable is AccessControl {
    uint256 public purchaseLimit;

    event PurchaseLimitChanged(uint256 newLimit);

    function setPurchaseLimit(uint256 newLimit) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        purchaseLimit = newLimit;
        emit PurchaseLimitChanged(newLimit);
    }

    modifier isUnderPurchaseLimit(address to, uint256 amount, ERC721 token) {
        if (to != address(0)) {
            uint256 resulting = token.balanceOf(to) + amount;
            if (resulting > purchaseLimit) {
                revert StdErrors.PurchaseLimitExceeded(purchaseLimit, resulting);
            }
        }
        _;
    }
}
