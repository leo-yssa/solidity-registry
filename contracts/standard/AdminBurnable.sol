// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./StdErrors.sol";

abstract contract AdminBurnable {
    bool public isAdminBurnAllowed;

    struct AdminBurnSubject {
        uint256 tokenId;
        address tokenOwner;
    }

    modifier whenAdminCanBurn() {
        if (!isAdminBurnAllowed) revert StdErrors.AdminBurnNotAllowed();
        _;
    }

    event AdminBurned(AdminBurnSubject[] subjects);
    event AdminBurnPermissionUpdated(bool allowed);

    function _updateAdminBurnPermission(bool isAdminBurnAllowed_) internal virtual {
        isAdminBurnAllowed = isAdminBurnAllowed_;
        emit AdminBurnPermissionUpdated(isAdminBurnAllowed_);
    }

    function adminBurn(AdminBurnSubject[] calldata subjects) external virtual;
}