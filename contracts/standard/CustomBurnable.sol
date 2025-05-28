// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract CustomBurnable is AccessControl {
    address public burnAddress;

    function setBurnAddress(address burnAddress_) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        burnAddress = burnAddress_;
    }

    function burnOriginals(uint256 tokenId) external virtual;
}
