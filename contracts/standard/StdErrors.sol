// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice Shared custom errors for the Solidity registry standard modules.
library StdErrors {
    error ZeroAddress();

    // Generic authorization / policy
    error ContractsNotAllowed();

    // Sale / minting
    error SaleNotStarted(uint256 start, uint256 current);
    error SaleEnded(uint256 end, uint256 current);
    error MintAmountZero();
    error MintAmountTooLarge(uint256 amount, uint256 max);
    error MaxSupplyExceeded(uint256 currentSupply, uint256 requested, uint256 maxSupply);
    error MintLimitExceeded(uint256 currentSupply, uint256 requested, uint256 limit);
    error IncorrectPayment(uint256 expected, uint256 actual);
    error InvalidMerkleProof();

    // Transfers / limits
    error TransferNotAllowed();
    error PurchaseLimitExceeded(uint256 limit, uint256 resultingBalance);
    error TransferLimitedByBalance(uint256 requiredMinBalance, uint256 balance);
    error TransferLimitExceeded(uint256 tokenId, uint256 limit);

    // Tags
    error TagUnavailable(string tagName);
    error TagPaused(string tagName);

    // Token metadata / reveal
    error InvalidTokenId(uint256 tokenId);
    error AlreadyRevealed();

    // Burning
    error AdminBurnNotAllowed();
    error WrongTokenOwner(uint256 tokenId, address expectedOwner, address actualOwner);

    // ETH
    error EthTransferFailed(address to, uint256 amount);

    // MultiTransfer
    error RecipientIsContract(address recipient);
}

