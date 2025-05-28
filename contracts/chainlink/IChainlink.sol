// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../standard/IStandard.sol";

interface IChainlink is IStandard {
    function setTokenIdToAssetIndex(uint256 tokenId, uint256 assetIndex) external;
}