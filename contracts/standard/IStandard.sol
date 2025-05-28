// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IStandard {
    function mint(address to, uint256 tokenId) external;

    function setTokenOffset(uint256 offset) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function maxSupply() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);
}
