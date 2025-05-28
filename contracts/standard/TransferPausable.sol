// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract TransferPausable is AccessControl {
    bool public isTransferable;

    modifier whenTransferNotPaused(address from, address to) virtual {
        require(from == address(0) || to == address(0) || isTransferable == true, "Transfer not allowed");
        _;
    }

    function changeTransferStatus(bool isTransferable_) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        isTransferable = isTransferable_;
    }
}