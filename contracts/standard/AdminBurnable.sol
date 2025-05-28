// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract AdminBurnable {
    bool public isAdminBurnAllowed;

    struct AdminBurnSubject {
        uint256 tokenId;
        address tokenOwner;
    }

    modifier whenAdminCanBurn() {
        require(isAdminBurnAllowed, "Admin cannot burn");
        _;
    }

    event AdminBurned(AdminBurnSubject[] subjects);

    function _updateAdminBurnPermission(bool isAdminBurnAllowed_) internal virtual {
        isAdminBurnAllowed = isAdminBurnAllowed_;
    }

    function adminBurn(AdminBurnSubject[] calldata subjects) external virtual;
}