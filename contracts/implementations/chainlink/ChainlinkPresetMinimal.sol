// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../../standard/Standard.sol";

/// @notice Minimal preset compatible with `ARevealer` / `RevealMinter`.
contract ChainlinkPresetMinimal is Standard {
    mapping(uint256 => uint256) public tokenIdToAssetIndex;

    constructor(
        string memory name,
        string memory symbol,
        uint256 maxSupply,
        string memory originalsBaseURI
    ) Standard(name, symbol, maxSupply, originalsBaseURI) {}

    function setTokenIdToAssetIndex(uint256 tokenId, uint256 assetIndex) external onlyRole(MINTER_ROLE) {
        tokenIdToAssetIndex[tokenId] = assetIndex;
    }
}

