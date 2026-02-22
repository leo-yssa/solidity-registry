// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ATagPausableMinter.sol";
import "../StdErrors.sol";

abstract contract AExternalContractMinter is ATagPausableMinter {
    IStandard private standardInstance;
    address public seller;
    uint256 public currentPreMintAmount;
    uint256 public currentPublicMintAmount;

    constructor(
        address nftAddress,
        address withdrawAddress,
        bytes32 merkleRootHash
    ) ATagPausableMinter(nftAddress, withdrawAddress, merkleRootHash) {
        standardInstance = IStandard(nftAddress);
        seller = msg.sender;
    }

    function mappedAirdrop(MappedAirdropRecipient[] calldata recipients) external override virtual onlyOwner {
        for (uint256 i = 0; i < recipients.length; i++) {
            standardInstance.transferFrom(seller, recipients[i].receiver, recipients[i].tokenId);
        }
    }

    function mintPreSale(MintingToken[] calldata tokens, bytes32[] calldata _merkleProof) external override virtual payable nonReentrant {
        uint256 amount = tokens.length;
        _enforceMinterPolicy();

        uint256 nowTs = block.timestamp;
        if (nowTs < preMintStart) revert StdErrors.SaleNotStarted(preMintStart, nowTs);
        if (nowTs > preMintEnd) revert StdErrors.SaleEnded(preMintEnd, nowTs);
        if (amount == 0) revert StdErrors.MintAmountZero();
        if (amount > preMintTxMaxAmount) revert StdErrors.MintAmountTooLarge(amount, preMintTxMaxAmount);

        if (currentPreMintAmount + amount > preMintLimit) revert StdErrors.MintLimitExceeded(currentPreMintAmount, amount, preMintLimit);

        uint256 expected = preMintPrice * amount;
        if (expected != msg.value) revert StdErrors.IncorrectPayment(expected, msg.value);

        bytes32 leafHash = keccak256(abi.encodePacked(msg.sender));
        if (!MerkleProof.verify(_merkleProof, merkleRootHash, leafHash)) revert StdErrors.InvalidMerkleProof();

        _mintToken(msg.sender, tokens);

        currentPreMintAmount += amount;
        _forwardFunds(msg.value);
    }

    function mintPublicSale(MintingToken[] calldata tokens) external override virtual payable nonReentrant {
        uint256 amount = tokens.length;
        _enforceMinterPolicy();

        uint256 nowTs = block.timestamp;
        if (nowTs < publicMintStart) revert StdErrors.SaleNotStarted(publicMintStart, nowTs);
        if (nowTs > publicMintEnd) revert StdErrors.SaleEnded(publicMintEnd, nowTs);
        if (amount == 0) revert StdErrors.MintAmountZero();
        if (amount > publicMintTxMaxAmount) revert StdErrors.MintAmountTooLarge(amount, publicMintTxMaxAmount);

        if (currentPublicMintAmount + amount > publicMintLimit) revert StdErrors.MintLimitExceeded(currentPublicMintAmount, amount, publicMintLimit);

        uint256 expected = publicMintPrice * amount;
        if (expected != msg.value) revert StdErrors.IncorrectPayment(expected, msg.value);

        _mintToken(msg.sender, tokens);

        currentPublicMintAmount += amount;
        _forwardFunds(msg.value);
    }

    function _mintToken(address newOwner, MintingToken[] calldata tokens) internal override virtual {
        for (uint256 i = 0; i < tokens.length; i++) {
            standardInstance.transferFrom(seller, newOwner, tokens[i].tokenId);
        }
    }
}
