// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ATagPausableMinter.sol";

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
            standardInstance.transferFrom(this.seller(), recipients[i].receiver, recipients[i].tokenId);
        }
    }

    function mintPreSale(MintingToken[] calldata tokens, bytes32[] calldata _merkleProof) external override virtual payable {
        uint256 amount = tokens.length;
        require(block.timestamp >= preMintStart, "presale is not open yet");
        require(block.timestamp <= preMintEnd, "presale is ended");
        require(amount > 0, "Amount to mint should be a positive number");
        require(amount <= preMintTxMaxAmount, "You can mint up to 10 per transaction");

        address minter = _msgSender();
        require(tx.origin == minter, "Contracts are not allowed to mint");
        require(currentPreMintAmount + amount <= preMintLimit, "Cannot mint the beyond max preMintLimit");
        require(preMintPrice * amount == msg.value, "Payment is not equal to price");

        bytes32 leafHash = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRootHash, leafHash), "Your wallet is not in whitelist");

        _mintToken(msg.sender, tokens);

        currentPreMintAmount += amount;
        payable(withdrawAddress).transfer(msg.value);
    }

    function mintPublicSale(MintingToken[] calldata tokens) external override virtual payable {
        uint256 amount = tokens.length;
        require(block.timestamp >= publicMintStart, "Public sale is not open yet");
        require(block.timestamp <= publicMintEnd, "Public sale is ended");
        require(amount > 0, "Amount to mint should be a positive number");
        require(amount <= publicMintTxMaxAmount, "You can mint up to 10 per transaction");

        address minter = _msgSender();
        require(tx.origin == minter, "Contracts are not allowed to mint");
        require(currentPublicMintAmount + amount <= publicMintLimit, "Cannot mint the beyond max publicMintLimit");
        require(publicMintPrice * amount == msg.value, "Payment is not equal to price");

        _mintToken(msg.sender, tokens);

        currentPublicMintAmount += amount;
        payable(withdrawAddress).transfer(msg.value);
    }

    function _mintToken(address newOwner, MintingToken[] calldata tokens) internal override virtual {
        for (uint256 i = 0; i < tokens.length; i++) {
            standardInstance.transferFrom(this.seller(), newOwner, tokens[i].tokenId);
        }
    }
}
