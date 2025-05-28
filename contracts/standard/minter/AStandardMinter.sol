// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "../IStandard.sol";

abstract contract AStandardMinter is Ownable {
    uint256 public nextMintIndex;

    // Public-Sale Values
    uint256 public publicMintTxMaxAmount;
    uint256 public publicMintPrice;
    uint256 public publicMintStart;
    uint256 public publicMintEnd;
    uint256 public publicMintLimit;

    // Pre-Sale Values
    uint256 public preMintTxMaxAmount;
    uint256 public preMintPrice;
    uint256 public preMintStart;
    uint256 public preMintEnd;
    uint256 public preMintLimit;

    address public withdrawAddress;
    bytes32 public merkleRootHash;

    struct MappedAirdropRecipient {
        address receiver;
        uint256 tokenId;
    }

    struct MintingToken {
        uint256 tokenId;
    }

    IStandard private standardInstance;

    constructor(address nftAddress, address withdrawAddress_, bytes32 merkleRootHash_) {
        standardInstance = IStandard(nftAddress);
        withdrawAddress = withdrawAddress_;
        merkleRootHash = merkleRootHash_;
    }

    function setMerkleRootHash(bytes32 merkleRootHash_) external onlyOwner {
        merkleRootHash = merkleRootHash_;
    }

    function setWithdrawAddress(address withdrawAddress_) external onlyOwner {
        withdrawAddress = withdrawAddress_;
    }

    function setPreSaleValues(
        uint256 _preMintTxMaxAmount,
        uint256 _preMintPrice,
        uint256 _preMintStart,
        uint256 _preMintEnd,
        uint256 _preMintLimit
    ) external onlyOwner virtual {
        preMintTxMaxAmount = _preMintTxMaxAmount;
        preMintPrice = _preMintPrice;
        preMintStart = _preMintStart;
        preMintEnd = _preMintEnd;
        preMintLimit = _preMintLimit;
    }

    function setPublicSaleValues(
        uint256 _publicMintTxMaxAmount,
        uint256 _publicMintPrice,
        uint256 _publicMintStart,
        uint256 _publicMintEnd,
        uint256 _publicMintLimit
    ) external onlyOwner virtual {
        publicMintTxMaxAmount = _publicMintTxMaxAmount;
        publicMintPrice = _publicMintPrice;
        publicMintStart = _publicMintStart;
        publicMintEnd = _publicMintEnd;
        publicMintLimit = _publicMintLimit;
    }

    function mappedAirdrop(MappedAirdropRecipient[] calldata recipients) external virtual onlyOwner {
        require(
            standardInstance.totalSupply() + recipients.length <= standardInstance.maxSupply(),
            "Max supply exceeded"
        );
        for (uint256 i = 0; i < recipients.length; i++) {
            standardInstance.mint(recipients[i].receiver, recipients[i].tokenId);
        }
    }

    function mintPreSale(MintingToken[] calldata tokens, bytes32[] calldata _merkleProof) external virtual payable {
        uint256 amount = tokens.length;
        require(block.timestamp >= preMintStart, "presale is not open yet");
        require(block.timestamp <= preMintEnd, "presale is ended");
        require(amount > 0, "Amount to mint should be a positive number");
        require(amount <= preMintTxMaxAmount, "You can mint up to 10 per transaction");

        address minter = _msgSender();
        require(tx.origin == minter, "Contracts are not allowed to mint");
        require(standardInstance.totalSupply() + amount <= preMintLimit, "Cannot mint the beyond max preMintLimit");
        require(preMintPrice * amount == msg.value, "Payment is not equal to price");

        bytes32 leafHash = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRootHash, leafHash), "Your wallet is not in whitelist");

        _mintToken(msg.sender, tokens);

        payable(withdrawAddress).transfer(msg.value);
    }

    function mintPublicSale(MintingToken[] calldata tokens) external virtual payable {
        uint256 amount = tokens.length;
        require(block.timestamp >= publicMintStart, "Public sale is not open yet");
        require(block.timestamp <= publicMintEnd, "Public sale is ended");
        require(amount > 0, "Amount to mint should be a positive number");
        require(amount <= publicMintTxMaxAmount, "You can mint up to 10 per transaction");

        address minter = _msgSender();
        require(tx.origin == minter, "Contracts are not allowed to mint");
        require(standardInstance.totalSupply() + amount <= publicMintLimit, "Cannot mint the beyond max publicMintLimit");
        require(publicMintPrice * amount == msg.value, "Payment is not equal to price");

        _mintToken(msg.sender, tokens);

        payable(withdrawAddress).transfer(msg.value);
    }

    function _mintToken(address newOwner, MintingToken[] calldata tokens) internal virtual {
        for (uint256 i = 0; i < tokens.length; i++) {
            standardInstance.mint(newOwner, tokens[i].tokenId);
        }
    }
}
