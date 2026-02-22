// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./StdErrors.sol";

abstract contract TransferPausable is AccessControl {
    bool public isTransferable;

    modifier whenTransferNotPaused(address from, address to) virtual {
        if (from != address(0) && to != address(0) && !isTransferable) {
            revert StdErrors.TransferNotAllowed();
        }
        _;
    }

    event TransferStatusChanged(bool isTransferable);

    function changeTransferStatus(bool isTransferable_) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        isTransferable = isTransferable_;
        emit TransferStatusChanged(isTransferable_);
    }
}