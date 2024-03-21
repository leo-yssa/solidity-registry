// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFT is ERC721, ERC721URIStorage, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenCounter;

    event Mint(address _owner, uint256 _tokenId);

    struct NftInfo {
        uint256 tokenId;
        string tokenUri;
    }

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {
        transferOwnership(msg.sender);
    }

    function mint(address to, string memory uri) external onlyOwner {
        uint256 tokenId = _tokenCounter.current();
        _tokenCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        setApprovalForAll(to);
        emit Mint(to, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(IERC721, ERC721) {
        setApprovalForAll(to);
        safeTransferFrom(from, to, tokenId, "");
    }

    function setApprovalForAll(address to) internal onlyOwner {
        _setApprovalForAll(to, owner(), true);
    }

    function burn(uint256 _tokenId) public onlyOwner {
        _burn(_tokenId);
    }

    function _burn(
        uint256 tokenId
    ) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function getNftInfo(
        address _address
    ) public view returns (NftInfo[] memory) {
        uint256 counts = balanceOf(_address);
        NftInfo[] memory nftInfoList = new NftInfo[](counts);
        for (uint i = 0; i < counts; i++) {
            nftInfoList[i].tokenId = tokenOfOwnerByIndex(_address, i);
            nftInfoList[i].tokenUri = tokenURI(nftInfoList[i].tokenId);
        }
        return nftInfoList;
    }

    // ERC165
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721, ERC721URIStorage, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }
}
