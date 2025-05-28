// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ARevealer.sol";
import "../standard/Standard.sol";
import "../standard/minter/AStandardMinter.sol";

contract RevealMinter is ARevealer, AStandardMinter {
    IStandard private standardInstance;

    constructor(address nftAddress,
        uint64 subscriptionId,
        address coordinator,
        bytes32 gweiKeyHash,
        uint256 totalSupply,
        address withdrawAddress,
        bytes32 merkleRootHash) ARevealer(nftAddress, subscriptionId, coordinator, gweiKeyHash, totalSupply) AStandardMinter(nftAddress, withdrawAddress, merkleRootHash) {
        standardInstance = IStandard(nftAddress);
    }

    function mappedAirdrop(MappedAirdropRecipient[] calldata recipients) external virtual override onlyOwner {
        for (uint256 i = 0; i < recipients.length; i++) {
            standardInstance.mint(recipients[i].receiver, recipients[i].tokenId);
            tokenReveal(recipients[i].tokenId);
        }
    }

    function _mintToken(address newOwner, MintingToken[] calldata tokens) internal virtual override {
        for (uint256 i = 0; i < tokens.length; i++) {
            standardInstance.mint(newOwner, tokens[i].tokenId);
            tokenReveal(tokens[i].tokenId);
        }
    }
}