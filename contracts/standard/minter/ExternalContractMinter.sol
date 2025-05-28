// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./AExternalContractMinter.sol";

contract ExternalContractMinter is AExternalContractMinter {
    constructor(
        address nftAddress,
        address withdrawAddress,
        bytes32 merkleRootHash
    ) AExternalContractMinter(nftAddress, withdrawAddress, merkleRootHash) {}
}
