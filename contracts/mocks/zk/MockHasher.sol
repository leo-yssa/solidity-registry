// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../../zk-merkle-tree/MerkleTreeWithHistory.sol";

contract MockHasher is IHasher {
    uint256 private constant FIELD_SIZE =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;

    function MiMCSponge(
        uint256 in_xL,
        uint256 in_xR,
        uint256 k
    ) external pure override returns (uint256 xL, uint256 xR) {
        xL = addmod(addmod(in_xL, in_xR, FIELD_SIZE), k, FIELD_SIZE);
        xR = 0;
    }
}

