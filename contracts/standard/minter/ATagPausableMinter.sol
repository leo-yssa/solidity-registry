// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./AStandardMinter.sol";
import "../IStandardWithTag.sol";
import "../StdErrors.sol";

abstract contract ATagPausableMinter is AStandardMinter {

    struct MappedAirdropRecipientWithTag {
        address receiver;
        uint256 tokenId;
        string tagName;
    }

    IStandardWithTag private standardInstance;

    constructor(address nftAddress, address withdrawAddress, bytes32 merkleRootHash) AStandardMinter(nftAddress, withdrawAddress, merkleRootHash){
        standardInstance = IStandardWithTag(nftAddress);
    }

    function mappedAirdropWithTag(MappedAirdropRecipientWithTag[] calldata recipients) external virtual onlyOwner {
        uint256 supply = standardInstance.totalSupply();
        uint256 maxSupply = standardInstance.maxSupply();
        if (supply + recipients.length > maxSupply) {
            revert StdErrors.MaxSupplyExceeded(supply, recipients.length, maxSupply);
        }
        for (uint256 i = 0; i < recipients.length; i++) {
            standardInstance.assignTagToTokenId(recipients[i].tagName, recipients[i].tokenId);
            standardInstance.mint(recipients[i].receiver, recipients[i].tokenId);
        }
    }

    function mintPreSaleWithTag(uint256 _mintAmount, bytes32[] calldata _merkleProof, string calldata tagName) external virtual payable nonReentrant {
        _enforceMinterPolicy();

        uint256 nowTs = block.timestamp;
        if (nowTs < preMintStart) revert StdErrors.SaleNotStarted(preMintStart, nowTs);
        if (nowTs > preMintEnd) revert StdErrors.SaleEnded(preMintEnd, nowTs);
        if (_mintAmount == 0) revert StdErrors.MintAmountZero();
        if (_mintAmount > preMintTxMaxAmount) revert StdErrors.MintAmountTooLarge(_mintAmount, preMintTxMaxAmount);

        uint256 supply = standardInstance.totalSupply();
        if (supply + _mintAmount > preMintLimit) revert StdErrors.MintLimitExceeded(supply, _mintAmount, preMintLimit);

        uint256 expected = preMintPrice * _mintAmount;
        if (expected != msg.value) revert StdErrors.IncorrectPayment(expected, msg.value);

        bytes32 leafHash = keccak256(abi.encodePacked(msg.sender));
        if (!MerkleProof.verify(_merkleProof, merkleRootHash, leafHash)) revert StdErrors.InvalidMerkleProof();

        _mintTokenWithTag(msg.sender, _mintAmount, tagName);

        _forwardFunds(msg.value);
    }

    function mintPublicSaleWithTag(uint256 _mintAmount, string calldata tagName) external virtual payable nonReentrant {
        _enforceMinterPolicy();

        uint256 nowTs = block.timestamp;
        if (nowTs < publicMintStart) revert StdErrors.SaleNotStarted(publicMintStart, nowTs);
        if (nowTs > publicMintEnd) revert StdErrors.SaleEnded(publicMintEnd, nowTs);
        if (_mintAmount == 0) revert StdErrors.MintAmountZero();
        if (_mintAmount > publicMintTxMaxAmount) revert StdErrors.MintAmountTooLarge(_mintAmount, publicMintTxMaxAmount);

        uint256 supply = standardInstance.totalSupply();
        if (supply + _mintAmount > publicMintLimit) revert StdErrors.MintLimitExceeded(supply, _mintAmount, publicMintLimit);

        uint256 expected = publicMintPrice * _mintAmount;
        if (expected != msg.value) revert StdErrors.IncorrectPayment(expected, msg.value);

        _mintTokenWithTag(msg.sender, _mintAmount, tagName);

        _forwardFunds(msg.value);
    }

    function _mintTokenWithTag(address newOwner, uint256 amount, string calldata tagName) internal virtual {
        for (uint256 i = 0; i < amount; i++) {
            standardInstance.assignTagToTokenId(tagName, nextMintIndex);
            standardInstance.mint(newOwner, nextMintIndex);
            nextMintIndex += 1;
        }
    }
}
