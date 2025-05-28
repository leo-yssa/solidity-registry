// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract TagPausable {

    mapping(string => bool) public tagExistsMap;
    mapping(string => bool) public tagPausedMap;
    mapping(uint256 => string) public tagByTokenId;

    modifier whenTagNotPaused(uint256 tokenId) {
        string memory tagName = tagByTokenId[tokenId];
        require(tagExistsMap[tagName], "tag is unavailable");
        require(!tagPausedMap[tagName], "tag is paused");
        _;
    }

    modifier whenTagExists(string memory tagName) {
        require(tagExistsMap[tagName] == true, "tag is unavailable");
        _;
    }

    event TagExistenceUpdated(string indexed tagName, bool exist);
    event TagAssignedToTokenId(uint256 indexed tokenId, string tagName);

    function isTagOnPaused(uint256 tokenId) external view virtual returns (bool) {
        string memory tagName = tagByTokenId[tokenId];
        return !tagExistsMap[tagName] || tagPausedMap[tagName];
    }

    function _updateTagExistence(string memory tagName, bool exist) internal virtual {
        tagExistsMap[tagName] = exist;

        emit TagExistenceUpdated(tagName, exist);
    }

    function _assignTagToTokenId(string memory tagName, uint256 tokenId) internal virtual whenTagExists(tagName) {
        tagByTokenId[tokenId] = tagName;

        emit TagAssignedToTokenId(tokenId, tagName);
    }

    function _updateTagPausedStatus(string memory tagName, bool pause) internal virtual whenTagExists(tagName) {
        tagPausedMap[tagName] = pause;
    }
}