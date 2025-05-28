// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract Lottery is AccessControl, VRFConsumerBaseV2Plus {

    struct DiceInfo {
        address[] applicants;
        uint32 numWord;
        bool isWinner;
    }

    struct Applicant {
        address wallet;
        bool isWinner;
    }

    uint256 s_subscriptionId;
    bytes32 s_keyHash;
    uint32 callbackGasLimit = 2500000;
    uint16 requestConfirmations = 5;
    bytes32 public constant ROLLER_ROLE = keccak256("ROLLER_ROLE");

    // map vrf requestId to random numbers
    mapping(uint256 => uint256[]) public s_results;
    // map collection to winners;
    mapping(address => address[]) public collectionToWinners;
    // map vrf requestId to collection
    mapping(uint256 => address) public requestIdToCollection;
    // map collection to DiceInfo
    mapping(address => DiceInfo) public collectionToDiceInfo;
    // map collection to Applicants
    mapping(address => Applicant[]) public collectionToApplicants;

    event DiceRolled(uint256 indexed requestId, address indexed collection);
    event DiceLanded(uint256 indexed requestId, uint256[] indexed result);

    constructor(uint256 _subscriptionId, address _vrfCoordinator, bytes32 _keyHash) VRFConsumerBaseV2Plus(_vrfCoordinator) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ROLLER_ROLE, msg.sender);
        s_subscriptionId = _subscriptionId;
        s_keyHash = _keyHash;
    }
    function isMajority(uint32 _numWord, address[] memory _applicants) internal pure returns (bool) {
        uint32 majority = uint32(_applicants.length) / uint32(2);
        return (_applicants.length > 2 && _numWord > majority);
    }
    // ADD CONSUMER BEFORE YOU ROLL DICE
    function rollDice(uint32 _numWord, address _collection, address[] memory _applicants) external onlyRole(ROLLER_ROLE) returns (uint256 requestId) {
        require(_applicants.length >= _numWord, "applicants should be same or more than numWord");
        require(_numWord > 0 && _numWord <= 50, "numWords range is 1 ~ 50");
        delete collectionToApplicants[_collection];
        delete collectionToWinners[_collection];
        bool _isWinner = true;
        if (isMajority(_numWord, _applicants)) {
            _numWord = uint32(_applicants.length) - _numWord;
            _isWinner = false;
        }
        requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash : s_keyHash,
                subId : s_subscriptionId,
                requestConfirmations : requestConfirmations,
                callbackGasLimit : callbackGasLimit,
                numWords : _numWord,
                extraArgs : VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment : true})
                )
            })
        );
        DiceInfo memory diceInfo = DiceInfo({
            applicants: _applicants,
            numWord: _numWord,
            isWinner: _isWinner
        });
        requestIdToCollection[requestId] = _collection;
        collectionToDiceInfo[_collection] = diceInfo;
        emit DiceRolled(requestId, _collection);
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) internal override {
        s_results[requestId] = new uint256[](randomWords.length);
        for (uint256 i = 0; i < randomWords.length; i++) {
            uint256 randomNumber = randomWords[i] % collectionToDiceInfo[requestIdToCollection[requestId]].applicants.length;
            address winner = collectionToDiceInfo[requestIdToCollection[requestId]].applicants[randomNumber];
            s_results[requestId][i] = randomNumber;
            collectionToWinners[requestIdToCollection[requestId]].push(winner);
        }
        if (randomWords.length == uint256(0)) {
            for (uint16 i = 0; i < collectionToDiceInfo[requestIdToCollection[requestId]].applicants.length; i++) {
                collectionToApplicants[requestIdToCollection[requestId]].push(Applicant({
                        wallet: collectionToDiceInfo[requestIdToCollection[requestId]].applicants[i],
                        isWinner: true
                    })
                );
            }
        } else {
            for (uint16 i = 0; i < collectionToDiceInfo[requestIdToCollection[requestId]].applicants.length; i++) {
                collectionToApplicants[requestIdToCollection[requestId]].push(Applicant({
                    wallet: collectionToDiceInfo[requestIdToCollection[requestId]].applicants[i],
                    isWinner: isWinner(
                        requestIdToCollection[requestId], 
                        collectionToDiceInfo[requestIdToCollection[requestId]].applicants[i],
                        collectionToDiceInfo[requestIdToCollection[requestId]].isWinner
                    )
                }));
            }
        }
        emit DiceLanded(requestId, s_results[requestId]);
    }

    function getWinners(address _collection) public view returns (Applicant[] memory) {
        return collectionToApplicants[_collection];
    }

    function isWinner(address _collection, address _target, bool _isWinner) public view returns (bool) {
        for (uint16 i = 0; i < collectionToWinners[_collection].length; i++) {
            if (keccak256(abi.encodePacked(collectionToWinners[_collection][i])) == keccak256(abi.encodePacked(_target))) {
                return _isWinner;
            }
        }
        return !_isWinner;
    }
}
