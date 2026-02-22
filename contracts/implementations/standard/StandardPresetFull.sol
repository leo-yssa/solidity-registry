// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "../../standard/Standard.sol";
import "../../standard/CustomBurnable.sol";
import "../../standard/TransferPausable.sol";
import "../../standard/CustomRevealer.sol";
import "../../standard/TagPausable.sol";
import "../../standard/AdminBurnable.sol";
import "../../standard/TransferLimitable.sol";
import "../../standard/PurchaseLimitable.sol";
import "../../standard/StdErrors.sol";

contract StandardPresetFull is Standard, CustomBurnable, TransferPausable, CustomRevealer, TagPausable, AdminBurnable, TransferLimitable, PurchaseLimitable {

    constructor(
        string memory name,
        string memory symbol,
        uint256 maxSupply,
        string memory originalsBaseURI
    ) Standard(name, symbol, maxSupply, originalsBaseURI) {
        // sensible defaults so the mixins don't block mint/transfer out of the box
        isTransferable = true;
        purchaseLimit = type(uint256).max;
        _setTransferLimit(type(uint256).max);
        _setMinBalanceToTransfer(0);
        _updateTagExistence("", true);
    }

    function burnOriginals(uint256 tokenId) external virtual override {
        address to = burnAddress;
        if (to == address(0)) revert StdErrors.ZeroAddress();
        transferFrom(msg.sender, to, tokenId);
    }

    function updateTagExistence(string memory tagName, bool exist) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _updateTagExistence(tagName, exist);
    }

    function assignTagToTokenId(string memory tagName, uint256 tokenId) external onlyRole(MINTER_ROLE) {
        _assignTagToTokenId(tagName, tokenId);
    }

    function updateTagPausedStatus(string memory tagName, bool pause) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _updateTagPausedStatus(tagName, pause);
    }

    function updateAdminBurnPermission(bool isAdminBurnAllowed_) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _updateAdminBurnPermission(isAdminBurnAllowed_);
    }

    function adminBurn(AdminBurnSubject[] calldata subjects) external override onlyRole(DEFAULT_ADMIN_ROLE) whenAdminCanBurn {
        for (uint256 i = 0; i < subjects.length; i++) {
            address actual = ownerOf(subjects[i].tokenId);
            if (actual != subjects[i].tokenOwner) {
                revert StdErrors.WrongTokenOwner(subjects[i].tokenId, subjects[i].tokenOwner, actual);
            }
            _burn(subjects[i].tokenId);
        }
        emit AdminBurned(subjects);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    )
        internal
        override
        whenNotPaused
        whenTransferNotPaused(from, to)
        whenTagNotPaused(tokenId)
        checkMinimumBalanceToTransfer(from, to)
        isUnderPurchaseLimit(to, batchSize, this)
    {
        if (from != address(0) && to != address(0)) {
            if (!isUnderTransferLimit(tokenId)) revert StdErrors.TransferLimitExceeded(tokenId, getTransferLimit());
            _incrementTransferCount(tokenId);
        }
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId) public view override (Standard, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view override(ERC721, TransferLimitable) returns (uint256) {
        return ERC721.balanceOf(owner);
    }
}
