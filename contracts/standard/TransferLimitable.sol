// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./StdErrors.sol";

abstract contract TransferLimitable is Ownable {
    uint256 internal _transferLimit;
    uint256 internal _minBalanceToTransfer;

    // Mapping from token ID to transfer count
    mapping(uint256 => uint256) private _transferCounts;

    event TransferLimitChanged(uint256 newTransferLimit);
    event MinBalanceToTransferChanged(uint256 newMinBalance);

    function setTransferLimit(uint256 transferLimit) public onlyOwner {
        _transferLimit = transferLimit;
        emit TransferLimitChanged(transferLimit);
    }

    function setMinBalanceToTransfer(uint256 minBalance) public onlyOwner {
        _minBalanceToTransfer = minBalance;
        emit MinBalanceToTransferChanged(minBalance);
    }

    function _setTransferLimit(uint256 transferLimit) internal {
        _transferLimit = transferLimit;
        emit TransferLimitChanged(transferLimit);
    }

    function _setMinBalanceToTransfer(uint256 minBalance) internal {
        _minBalanceToTransfer = minBalance;
        emit MinBalanceToTransferChanged(minBalance);
    }

    function getTransferCount(uint256 tokenId) public view returns (uint256) {
        return _transferCounts[tokenId];
    }

    function getTransferLimit() public view returns (uint256) {
        return _transferLimit;
    }

    function getMinBalanceToTransfer() public view returns (uint256) {
        return _minBalanceToTransfer;
    }

    function isUnderTransferLimit(uint256 tokenId) public view returns (bool) {
        return _transferCounts[tokenId] < _transferLimit;
    }

    function _incrementTransferCount(uint256 tokenId) internal {
        _transferCounts[tokenId] += 1;
    }

    // Abstract function to get the NFT balance of an address
    function balanceOf(address owner) public view virtual returns (uint256);

    modifier checkMinimumBalanceToTransfer(address from, address to) {
        if (from != address(0) && to != address(0)) {
            uint256 bal = balanceOf(from);
            if (bal <= _minBalanceToTransfer) {
                revert StdErrors.TransferLimitedByBalance(_minBalanceToTransfer, bal);
            }
        }
        _;
    }
}
