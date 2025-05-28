// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IStandard.sol";

interface IStandardWithTag is IStandard {
    function assignTagToTokenId(string memory tagName, uint256 tokenId) external;
}
