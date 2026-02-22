// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./StdErrors.sol";

abstract contract TagPausable {

    mapping(string => bool) public tagExistsMap;
    mapping(string => bool) public tagPausedMap;
    mapping(uint256 => string) public tagByTokenId;

    modifier whenTagNotPaused(uint256 tokenId) {
        string memory tagName = tagByTokenId[tokenId];
        if (!tagExistsMap[tagName]) revert StdErrors.TagUnavailable(tagName);
        if (tagPausedMap[tagName]) revert StdErrors.TagPaused(tagName);
        _;
    }

    modifier whenTagExists(string memory tagName) {
        if (!tagExistsMap[tagName]) revert StdErrors.TagUnavailable(tagName);
        _;
    }

    event TagExistenceUpdated(string indexed tagName, bool exist);
    event TagAssignedToTokenId(uint256 indexed tokenId, string tagName);
    event TagPausedStatusUpdated(string indexed tagName, bool paused);

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
        emit TagPausedStatusUpdated(tagName, pause);
    }
}