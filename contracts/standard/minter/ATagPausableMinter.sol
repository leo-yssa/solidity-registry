// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./AStandardMinter.sol";
import "../IStandardWithTag.sol";

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
        require(
            standardInstance.totalSupply() + recipients.length <= standardInstance.maxSupply(),
            "Max supply exceeded"
        );
        for (uint256 i = 0; i < recipients.length; i++) {
            standardInstance.assignTagToTokenId(recipients[i].tagName, recipients[i].tokenId);
            standardInstance.mint(recipients[i].receiver, recipients[i].tokenId);
        }
    }

    function mintPreSaleWithTag(uint256 _mintAmount, bytes32[] calldata _merkleProof, string calldata tagName) external virtual payable {
        require(block.timestamp >= preMintStart, "presale is not open yet");
        require(block.timestamp <= preMintEnd, "presale is ended");
        require(_mintAmount > 0, "Amount to mint should be a positive number");
        require(_mintAmount <= preMintTxMaxAmount, "You can mint up to 10 per transaction");

        address minter = _msgSender();
        require(tx.origin == minter, "Contracts are not allowed to mint");
        require(standardInstance.totalSupply() + _mintAmount <= preMintLimit, "Cannot mint the beyond max preMintLimit");
        require(preMintPrice * _mintAmount <= msg.value, "Payment is below the price");

        bytes32 leafHash = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRootHash, leafHash), "Your wallet is not in whitelist");

        _mintTokenWithTag(msg.sender, _mintAmount, tagName);

        payable(withdrawAddress).transfer(msg.value);
    }

    function mintPublicSaleWithTag(uint256 _mintAmount, string calldata tagName) external virtual payable {
        require(block.timestamp >= publicMintStart, "Public sale is not open yet");
        require(block.timestamp <= publicMintEnd, "Public sale is ended");
        require(_mintAmount > 0, "Amount to mint should be a positive number");
        require(_mintAmount <= publicMintTxMaxAmount, "You can mint up to 10 per transaction");

        address minter = _msgSender();
        require(tx.origin == minter, "Contracts are not allowed to mint");
        require(standardInstance.totalSupply() + _mintAmount <= publicMintLimit, "Cannot mint the beyond max publicMintLimit");
        require(publicMintPrice * _mintAmount <= msg.value, "Payment is below the price");

        _mintTokenWithTag(msg.sender, _mintAmount, tagName);

        payable(withdrawAddress).transfer(msg.value);
    }

    function _mintTokenWithTag(address newOwner, uint256 amount, string calldata tagName) internal virtual {
        for (uint256 i = 0; i < amount; i++) {
            standardInstance.assignTagToTokenId(tagName, nextMintIndex);
            standardInstance.mint(newOwner, nextMintIndex);
            nextMintIndex += 1;
        }
    }
}
