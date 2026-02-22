// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../../zk-merkle-tree/ZKTree.sol";

contract MockVerifier is IVerifier {
    function verifyProof(
        uint[2] memory,
        uint[2][2] memory,
        uint[2] memory,
        uint[2] memory
    ) external pure override returns (bool r) {
        return true;
    }
}

