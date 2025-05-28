// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Standard.sol";
import "./CustomBurnable.sol";
import "./TransferPausable.sol";
import "./CustomRevealer.sol";
import "./TagPausable.sol";
import "./AdminBurnable.sol";
import "./TransferLimitable.sol";
import "./PurchaseLimitable.sol";

contract AbiCollection is Standard, CustomBurnable, TransferPausable, CustomRevealer, TagPausable, AdminBurnable, TransferLimitable, PurchaseLimitable {

    constructor(
        string memory name,
        string memory symbol,
        uint256 maxSupply,
        string memory originalsBaseURI
    ) Standard(name, symbol, maxSupply, originalsBaseURI) {}

    function burnOriginals(uint256 tokenId) external virtual override {}

    function updateTagExistence(string memory tagName, bool exist) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _updateTagExistence(tagName, exist);
    }

    function assignTagToTokenId(string memory tagName, uint256 tokenId) external onlyRole(MINTER_ROLE) {
        _assignTagToTokenId(tagName, tokenId);
    }

    function updateTagPausedStatus(string memory tagName, bool pause) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _updateTagPausedStatus(tagName, pause);
    }

    function updateAdminBurnPermission(bool isAdminBurnAllowed) external virtual {
        _updateAdminBurnPermission(isAdminBurnAllowed);
    }

    function adminBurn(AdminBurnSubject[] calldata subjects) external override {
    }

    function supportsInterface(bytes4 interfaceId) public view override (Standard, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view override(ERC721, TransferLimitable) returns (uint256) {
        return ERC721.balanceOf(owner);
    }
}
