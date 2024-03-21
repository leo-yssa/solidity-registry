//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./IVote.sol";

contract ZKPVote is IVote {
    Info info;
    address private controller;
    mapping(address => bool) private votedAddress;
    mapping(address => uint256) private resultHash;
    mapping(address => bytes32) private historyRoot;
    mapping(uint256 => bytes32) private traitRoot;

    modifier onlyController() {
        require(controller == msg.sender, "caller is not controller");
        _;
    }

    constructor(
        address _controller,
        address _owner,
        string memory _name,
        uint256 _totalReward,
        uint256 _perReward,
        bool _zkp,
        uint256 _totalSupply,
        bool _targeting,
        bool _condition,
        address[] memory _historyList,
        bytes32[] memory _historyRoot,
        address[] memory _nftList,
        uint256[] memory _traitList,
        bytes32[] memory _traitRoot
    ) payable {
        controller = _controller;
        info.owner = _owner;
        info.nftList = _nftList;
        info.name = _name;
        info.ca = address(this);
        info.totalReward = _totalReward;
        info.perReward = _perReward;
        info.completed = false;
        info.zkp = _zkp;
        info.totalSupply = _totalSupply;
        info.targeting = _targeting;
        info.condition = _condition;
        for (uint256 i = 0; i < _historyList.length; i++) {
            historyRoot[_historyList[i]] = _historyRoot[i];
        }
        for (uint256 i = 0; i < _traitList.length; i++) {
            traitRoot[_traitList[i]] = _traitRoot[i];
        }
    }

    function verifyHistoryRoot(
        address _voter,
        address _history,
        bytes32[] memory _historyProof
    ) external view returns (bool) {
        bytes32 root = historyRoot[_history];
        if (root == bytes32(0)) {
            return false;
        }
        return
            MerkleProof.verify(
                _historyProof,
                root,
                keccak256(abi.encodePacked(_voter))
            );
    }

    function verifyTraitRoot(
        bytes32 _traitLeaf,
        uint256 _trait,
        bytes32[] memory _traitProof
    ) external view returns (bool) {
        bytes32 root = traitRoot[_trait];
        if (root == bytes32(0)) {
            return false;
        }
        return MerkleProof.verify(_traitProof, root, _traitLeaf);
    }

    function verifyNftOwner(
        address _voter,
        address _nft,
        uint256 _nftId
    ) external view returns (bool) {
        if (info.nftList.length == 0) {
            return true;
        }
        for (uint256 i = 0; i < info.nftList.length; i++) {
            if (info.nftList[i] == _nft) {
                IERC721 erc721 = IERC721(_nft);
                if (_voter == erc721.ownerOf(_nftId)) {
                    return true;
                }
            }
        }
        return false;
    }

    function execute(
        address _voter,
        uint256 _result
    ) external payable onlyController {
        require(
            !votedAddress[_voter],
            "this address was already received reward"
        );

        votedAddress[_voter] = true;
        resultHash[_voter] = _result;

        info.count += 1;
    }

    function get() external view onlyController returns (Info memory) {
        return info;
    }

    function stop(address _owner) external onlyController {
        require(_owner == info.owner, "only owner can stop vote");
        info.stopped = true;
    }

    function complete(address _owner) external onlyController {
        require(_owner == info.owner, "only owner can stop vote");
        info.completed = true;
    }

    function refund(address _owner) external payable onlyController {
        require(_owner == info.owner, "only owner can refund");
    }
}
