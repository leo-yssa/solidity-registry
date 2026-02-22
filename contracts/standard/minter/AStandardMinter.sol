// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "../IStandard.sol";
import "../StdErrors.sol";

abstract contract AStandardMinter is Ownable, ReentrancyGuard {
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
    bool public enforceEOA;

    event WithdrawAddressUpdated(address indexed previous, address indexed current);
    event MerkleRootUpdated(bytes32 previous, bytes32 current);
    event EnforceEOAUpdated(bool enforceEOA);
    event PreSaleValuesUpdated(
        uint256 txMaxAmount,
        uint256 price,
        uint256 start,
        uint256 end,
        uint256 limit
    );
    event PublicSaleValuesUpdated(
        uint256 txMaxAmount,
        uint256 price,
        uint256 start,
        uint256 end,
        uint256 limit
    );

    struct MappedAirdropRecipient {
        address receiver;
        uint256 tokenId;
    }

    struct MintingToken {
        uint256 tokenId;
    }

    IStandard private standardInstance;

    constructor(address nftAddress, address withdrawAddress_, bytes32 merkleRootHash_) {
        if (nftAddress == address(0) || withdrawAddress_ == address(0)) revert StdErrors.ZeroAddress();
        standardInstance = IStandard(nftAddress);
        withdrawAddress = withdrawAddress_;
        merkleRootHash = merkleRootHash_;
    }

    function setMerkleRootHash(bytes32 merkleRootHash_) external onlyOwner {
        bytes32 prev = merkleRootHash;
        merkleRootHash = merkleRootHash_;
        emit MerkleRootUpdated(prev, merkleRootHash_);
    }

    function setWithdrawAddress(address withdrawAddress_) external onlyOwner {
        if (withdrawAddress_ == address(0)) revert StdErrors.ZeroAddress();
        address prev = withdrawAddress;
        withdrawAddress = withdrawAddress_;
        emit WithdrawAddressUpdated(prev, withdrawAddress_);
    }

    function setEnforceEOA(bool enforceEOA_) external onlyOwner {
        enforceEOA = enforceEOA_;
        emit EnforceEOAUpdated(enforceEOA_);
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
        emit PreSaleValuesUpdated(_preMintTxMaxAmount, _preMintPrice, _preMintStart, _preMintEnd, _preMintLimit);
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
        emit PublicSaleValuesUpdated(
            _publicMintTxMaxAmount,
            _publicMintPrice,
            _publicMintStart,
            _publicMintEnd,
            _publicMintLimit
        );
    }

    function mappedAirdrop(MappedAirdropRecipient[] calldata recipients) external virtual onlyOwner {
        uint256 supply = standardInstance.totalSupply();
        uint256 maxSupply = standardInstance.maxSupply();
        if (supply + recipients.length > maxSupply) {
            revert StdErrors.MaxSupplyExceeded(supply, recipients.length, maxSupply);
        }
        for (uint256 i = 0; i < recipients.length; i++) {
            standardInstance.mint(recipients[i].receiver, recipients[i].tokenId);
        }
    }

    function mintPreSale(MintingToken[] calldata tokens, bytes32[] calldata _merkleProof) external virtual payable nonReentrant {
        uint256 amount = tokens.length;
        _enforceMinterPolicy();

        uint256 nowTs = block.timestamp;
        if (nowTs < preMintStart) revert StdErrors.SaleNotStarted(preMintStart, nowTs);
        if (nowTs > preMintEnd) revert StdErrors.SaleEnded(preMintEnd, nowTs);
        if (amount == 0) revert StdErrors.MintAmountZero();
        if (amount > preMintTxMaxAmount) revert StdErrors.MintAmountTooLarge(amount, preMintTxMaxAmount);

        uint256 supply = standardInstance.totalSupply();
        if (supply + amount > preMintLimit) revert StdErrors.MintLimitExceeded(supply, amount, preMintLimit);

        uint256 expected = preMintPrice * amount;
        if (expected != msg.value) revert StdErrors.IncorrectPayment(expected, msg.value);

        bytes32 leafHash = keccak256(abi.encodePacked(msg.sender));
        if (!MerkleProof.verify(_merkleProof, merkleRootHash, leafHash)) revert StdErrors.InvalidMerkleProof();

        _mintToken(msg.sender, tokens);

        _forwardFunds(msg.value);
    }

    function mintPublicSale(MintingToken[] calldata tokens) external virtual payable nonReentrant {
        uint256 amount = tokens.length;
        _enforceMinterPolicy();

        uint256 nowTs = block.timestamp;
        if (nowTs < publicMintStart) revert StdErrors.SaleNotStarted(publicMintStart, nowTs);
        if (nowTs > publicMintEnd) revert StdErrors.SaleEnded(publicMintEnd, nowTs);
        if (amount == 0) revert StdErrors.MintAmountZero();
        if (amount > publicMintTxMaxAmount) revert StdErrors.MintAmountTooLarge(amount, publicMintTxMaxAmount);

        uint256 supply = standardInstance.totalSupply();
        if (supply + amount > publicMintLimit) revert StdErrors.MintLimitExceeded(supply, amount, publicMintLimit);

        uint256 expected = publicMintPrice * amount;
        if (expected != msg.value) revert StdErrors.IncorrectPayment(expected, msg.value);

        _mintToken(msg.sender, tokens);

        _forwardFunds(msg.value);
    }

    function _mintToken(address newOwner, MintingToken[] calldata tokens) internal virtual {
        for (uint256 i = 0; i < tokens.length; i++) {
            standardInstance.mint(newOwner, tokens[i].tokenId);
        }
    }

    function _forwardFunds(uint256 amount) internal {
        (bool ok, ) = withdrawAddress.call{value: amount}("");
        if (!ok) revert StdErrors.EthTransferFailed(withdrawAddress, amount);
    }

    function _enforceMinterPolicy() internal view virtual {
        if (enforceEOA && msg.sender != tx.origin) revert StdErrors.ContractsNotAllowed();
    }
}
