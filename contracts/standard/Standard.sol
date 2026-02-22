// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./StdErrors.sol";

contract Standard is ERC721, Pausable, AccessControl, ERC721Burnable, Ownable {
    using Strings for uint256;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 private _totalSupply;
    string private _originalsBaseURI;
    bool private _revealed;
    uint256 public tokenOffset;
    uint256 public immutable maxSupply;

    event BaseURIUpdated(string baseURI);
    event TokenOffsetSet(uint256 offset);

    constructor(
        string memory name,
        string memory symbol,
        uint256 maxSupply_,
        string memory originalsBaseURI
    ) ERC721(name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _originalsBaseURI = originalsBaseURI;
        maxSupply = maxSupply_;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function mint(address to, uint256 tokenId) public onlyRole(MINTER_ROLE) {
        _mint(to, tokenId);
    }

    //Reveal
    function setTokenOffset(uint256 offset) external onlyRole(MINTER_ROLE) {
        if (_revealed) revert StdErrors.AlreadyRevealed();

        _revealed = true;
        tokenOffset = offset;
        emit TokenOffsetSet(offset);
    }

    function setBaseURI(string memory baseURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _originalsBaseURI = baseURI;
        emit BaseURIUpdated(baseURI);
    }

    function _baseURI() internal view override returns (string memory) {
        return _originalsBaseURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal virtual override whenNotPaused {
        if (from == address(0)) {
            _totalSupply += batchSize;
        } else if (to == address(0)) {
            _totalSupply -= batchSize;
        }
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert StdErrors.InvalidTokenId(tokenId);

        uint256 shiftedTokenId = ((tokenId + tokenOffset) % maxSupply);
        string memory baseURI = _baseURI();

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, shiftedTokenId.toString(), ".json")) : "";
    }

    // The following functions are overrides required by Solidity.
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
