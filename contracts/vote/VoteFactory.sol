//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IVote.sol";
import "./Vote.sol";
import "./ZKPVote.sol";

/// @notice Vote factory/registry. Execution is handled by `VoteExecutor`.
contract VoteFactory is Ownable {
    uint256[] private voteList;
    mapping(uint256 => address) private votes;
    mapping(bytes32 => bool) private names;

    address public executor;

    event Create(address owner, string name);
    event VoteCreated(
        uint256 indexed hash,
        address indexed vote,
        address indexed owner,
        string name,
        bool zkp
    );
    event ExecutorUpdated(address indexed executor);

    constructor() {
        transferOwnership(msg.sender);
    }

    function setExecutor(address executor_) external onlyOwner {
        require(executor_ != address(0), "executor cannot be zero");
        executor = executor_;
        emit ExecutorUpdated(executor_);
    }

    function getVoteAddress(uint256 _hash) external view returns (address) {
        return votes[_hash];
    }

    function checkTargetingCondition(
        address[] memory _historyList,
        bytes32[] memory _historyRoot,
        address[] memory _nftList,
        uint256[] memory _traitList,
        bytes32[] memory _traitRoot
    ) private pure returns (bool) {
        require(
            (_historyList.length == _historyRoot.length) &&
                (_traitList.length == _traitRoot.length),
            "incorrect targeting conditions"
        );
        bool historyCheck = true;
        for (uint256 i = 0; i < _historyRoot.length; i++) {
            if (_historyRoot[i] == bytes32(0)) {
                historyCheck = false;
            }
        }
        bool nftListCheck = true;
        for (uint256 i = 0; i < _nftList.length; i++) {
            if (_nftList[i] == address(0)) {
                nftListCheck = false;
                break;
            }
        }
        bool traitCheck = true;
        for (uint256 i = 0; i < _traitRoot.length; i++) {
            if (_traitRoot[i] == bytes32(0)) {
                traitCheck = false;
                break;
            }
        }
        return (historyCheck || nftListCheck || traitCheck);
    }

    /// The create function creates the normal or zkp vote.
    /// @param _name The name parameter is the name of the vote to be created.
    /// @param _hash The hash parameter is the hash of the vote to be created.
    /// @param _totalReward The totalReward parameter is the total reward of the vote to be created.
    /// @param _perReward The perReward parameter is the per reward of the vote to be created.
    /// @param _isZkp Whether it's a ZKP vote or not.
    /// @param _totalSupply The totalSupply parameter is the total supply of the vote to be created.
    /// @param _targeting Whether it's a targeting vote or not.
    /// @param _condition The condition parameter has a true value when the condition is or.
    /// @param _historyList The historyList parameter has the list of contract address related with history root.
    /// @param _historyRoot The historyRoot parameter has the list of root for merkle tree related with history list.
    /// @param _nftList The nftList parameter has the list of nft address related with targeting vote.
    /// @param _traitList The traitList parameter has the list of trait value related with trait root.
    /// @param _traitRoot The traitRoot parameter has the list of root for merkle tree related with trait list.
    function create(
        string memory _name,
        uint256 _hash,
        uint256 _totalReward,
        uint256 _perReward,
        bool _isZkp,
        uint256 _totalSupply,
        bool _targeting,
        bool _condition,
        address[] memory _historyList,
        bytes32[] memory _historyRoot,
        address[] memory _nftList,
        uint256[] memory _traitList,
        bytes32[] memory _traitRoot
    ) public payable {
        require(executor != address(0), "executor not set");
        require(votes[_hash] == address(0), "already registed vote");
        require(!names[keccak256(bytes(_name))], "already registed name");
        if (_targeting) {
            require(
                checkTargetingCondition(
                    _historyList,
                    _historyRoot,
                    _nftList,
                    _traitList,
                    _traitRoot
                ),
                "must be set targeting condition"
            );
        }
        IVote _vote;
        if (!_isZkp) {
            _vote = (new Vote){value: msg.value}(
                executor,
                msg.sender,
                _name,
                _totalReward,
                _perReward,
                _isZkp,
                _totalSupply,
                _targeting,
                _condition,
                _historyList,
                _historyRoot,
                _nftList,
                _traitList,
                _traitRoot
            );
        } else {
            _vote = new ZKPVote(
                executor,
                msg.sender,
                _name,
                _totalReward,
                _perReward,
                _isZkp,
                _totalSupply,
                _targeting,
                _condition,
                _historyList,
                _historyRoot,
                _nftList,
                _traitList,
                _traitRoot
            );
        }
        votes[_hash] = address(_vote);
        voteList.push(_hash);
        names[keccak256(bytes(_name))] = true;
        emit Create(msg.sender, _name);
        emit VoteCreated(_hash, address(_vote), msg.sender, _name, _isZkp);
    }

    /// The getVoteList function gives the information of the vote registered.
    function getVoteList() public view returns (uint256[] memory) {
        return voteList;
    }
}
