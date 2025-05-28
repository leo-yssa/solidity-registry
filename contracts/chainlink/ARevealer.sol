// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "./IChainlink.sol";

abstract contract ARevealer is Ownable, VRFConsumerBaseV2 {
    uint256 public constant _ROLL_IN_PROGRESS = 20000;

    // VRF setting
    uint64 public vrfSubscriptionId;
    bytes32 public vrfGweiKeyHash;
    uint32 public vrfCallbackGasLimit = 200000;
    uint32 public numWords = 1;
    uint16 public requestConfirmations = 3;

    // index setting
    uint256[] public assetIndexArray;
    uint256 public lastIndex;
    mapping(uint256 => uint256) public requestIdToTokenId;
    mapping(uint256 => uint256) public tokenIdToAssetIndex;

    uint256 public totalSupply;

    event RandomRolled(uint256 indexed requestId, uint256 tokenId);
    event RandomLanded(uint256 indexed tokenId, uint256 result);

    IChainlink immutable nftContract;
    VRFCoordinatorV2Interface immutable COORDINATOR;

    constructor(
        address nftAddress,
        uint64 subscriptionId,
        address coordinator,
        bytes32 gweiKeyHash, uint256 _totalSupply) VRFConsumerBaseV2(coordinator) {
        vrfSubscriptionId = subscriptionId;
        COORDINATOR = VRFCoordinatorV2Interface(coordinator);
        vrfGweiKeyHash = gweiKeyHash;
        nftContract = IChainlink(nftAddress);
        totalSupply = _totalSupply;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        uint256 tokenId = requestIdToTokenId[requestId];
        require(tokenIdToAssetIndex[tokenId] == _ROLL_IN_PROGRESS, "Not reveal progress status");

        uint16 randomIndex = uint16(randomWords[0] % assetIndexArray.length);
        uint256 assetIndex = assetIndexArray[randomIndex];
        tokenIdToAssetIndex[tokenId] = assetIndex;

        nftContract.setTokenIdToAssetIndex(tokenId, assetIndex);

        emit RandomLanded(tokenId, assetIndex);

        assetIndexArray[randomIndex] = assetIndexArray[assetIndexArray.length - 1];
        assetIndexArray.pop();
    }

    function tokenRevealByOwner(uint256 tokenId) external virtual onlyOwner returns (uint256 requestId) {
        uint256 assetIndex = tokenIdToAssetIndex[tokenId];

        require(assetIndex == _ROLL_IN_PROGRESS, "Not reveal progress status or Already revealed");

        requestId = COORDINATOR.requestRandomWords(
            vrfGweiKeyHash,
            vrfSubscriptionId,
            requestConfirmations,
            vrfCallbackGasLimit,
            numWords
        );

        requestIdToTokenId[requestId] = tokenId;

        emit RandomRolled(requestId, tokenId);
    }

    function tokenReveal(uint256 tokenId) internal virtual returns (uint256 requestId) {
        requestId = COORDINATOR.requestRandomWords(
            vrfGweiKeyHash,
            vrfSubscriptionId,
            requestConfirmations,
            vrfCallbackGasLimit,
            numWords
        );

        requestIdToTokenId[requestId] = tokenId;
        tokenIdToAssetIndex[tokenId] = _ROLL_IN_PROGRESS;
        nftContract.setTokenIdToAssetIndex(tokenId, _ROLL_IN_PROGRESS);

        emit RandomRolled(requestId, tokenId);
    }

    function getAssetIndexArraySize() external view returns (uint256) {
        return assetIndexArray.length;
    }

    function setChainlinkConfig(
        uint64 _vrfSubscriptionId,
        bytes32 _vrfGweiKeyHash,
        uint32 _vrfCallbackGasLimit,
        uint16 _requestConfirmations
    ) external onlyOwner {
        vrfSubscriptionId = _vrfSubscriptionId;
        vrfGweiKeyHash = _vrfGweiKeyHash;
        vrfCallbackGasLimit = _vrfCallbackGasLimit;
        requestConfirmations = _requestConfirmations;
    }

    function setAssetIndexArray(uint256 _size) external virtual onlyOwner {
        for (uint256 i = 1; i <= _size; i++) {
            uint256 newIndex = i + lastIndex;
            if (newIndex > totalSupply) {
                lastIndex = newIndex - 1;
                break;
            }
            assetIndexArray.push(newIndex);
            if (i == _size) {
                lastIndex = newIndex;
            }
        }
    }
}