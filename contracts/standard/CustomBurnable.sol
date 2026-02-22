// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./StdErrors.sol";

abstract contract CustomBurnable is AccessControl {
    address public burnAddress;

    event BurnAddressUpdated(address indexed burnAddress);

    function setBurnAddress(address burnAddress_) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        if (burnAddress_ == address(0)) revert StdErrors.ZeroAddress();
        burnAddress = burnAddress_;
        emit BurnAddressUpdated(burnAddress_);
    }

    function burnOriginals(uint256 tokenId) external virtual;
}
