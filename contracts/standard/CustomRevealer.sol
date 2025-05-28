// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract CustomRevealer is AccessControl {
    uint256 public revealDate;

    function setRevealDate(uint256 revealDate_) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        revealDate = revealDate_;
    }
}