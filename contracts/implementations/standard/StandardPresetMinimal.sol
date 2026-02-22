// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../../standard/Standard.sol";

/// @notice Minimal preset based on `Standard`.
/// @dev Kept intentionally small: use `StandardMinter` / role management externally.
contract StandardPresetMinimal is Standard {
    constructor(
        string memory name,
        string memory symbol,
        uint256 maxSupply,
        string memory originalsBaseURI
    ) Standard(name, symbol, maxSupply, originalsBaseURI) {}
}

