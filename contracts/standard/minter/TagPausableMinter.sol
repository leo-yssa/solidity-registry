// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ATagPausableMinter.sol";

contract TagPausableMinter is ATagPausableMinter {
    constructor(
        address nftAddress,
        address withdrawAddress,
        bytes32 merkleRootHash
    ) ATagPausableMinter(nftAddress, withdrawAddress, merkleRootHash) {}
}
