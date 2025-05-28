// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./AStandardMinter.sol";

contract StandardMinter is AStandardMinter {
    constructor(
        address nftAddress,
        address withdrawAddress,
        bytes32 merkleRootHash
    ) AStandardMinter(nftAddress, withdrawAddress, merkleRootHash) {}
}
