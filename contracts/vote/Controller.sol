//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IVote.sol";
import "./Vote.sol";
import "./ZKPVote.sol";
import "../zk-merkle-tree/ZKTree.sol";

contract Controller is ZKTree, Ownable {
    uint256[] private voteList;
    mapping(uint256 => address) private votes;
    mapping(bytes32 => bool) private names;

    event Create(address owner, string name);
    event Execute(address vote, address voter);
    event Complete(string name);
    event Stop(string name);
    event Refund(string name, uint256 balance);

    constructor(
        uint32 _levels,
        IHasher _hasher,
        IVerifier _verifier
    ) ZKTree(_levels, _hasher, _verifier) {
        transferOwnership(msg.sender);
    }

    /// The RegistCommitment function registers a commitment for ZKP.
    /// @param _commitment The commitment parameter is the commitment to be registered for ZKP.
    function registCommitment(uint256 _commitment) public onlyOwner {
        _commit(bytes32(_commitment));
    }

    function getVote(uint256 _hash) private view returns (IVote) {
        require(msg.sender != address(0), "sender cannot be zero address");
        require(votes[_hash] != address(0), "not registed vote");
        return IVote(votes[_hash]);
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
                address(this),
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
                address(this),
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
    }

    /// The execute function executes the normal or zkp vote.
    /// @param _hash The hash parameter is the hash of the vote to be executed.
    /// @param _voter The voter parameter is the address where the reward is received.
    /// @param _result The result parameter is the hash of the result of vote.
    /// @param _zkpProof The _zkpProof parameter is the proof of the ZKP.
    /// @param _historyList The historyList parameter has the list of contract address related with history proof.
    /// @param _historyProof The historyProof parameter has the list of proof for merkle tree related with history list.
    /// @param _traitList The traiList parameter has the list of trait value related with trait proof.
    /// @param _traitProof The traitRoot parameter has the list of root for merkle tree related with trait list.
    /// @param _nft The nft parameter has the list of nft address related with voter.
    /// @param _nftId The nftId parameter has the list of nft id related with voter.
    function execute(
        uint256 _hash,
        address _voter,
        uint256 _result,
        uint256[] memory _zkpProof,
        address[] memory _historyList,
        bytes32[][] memory _historyProof,
        uint256[] memory _traitList,
        bytes32[][] memory _traitProof,
        string[] memory _traitNfts,
        address[] memory _nft,
        uint256[] memory _nftId
    ) public onlyOwner {
        IVote vote = getVote(_hash);
        IVote.Info memory voteInfo = vote.get();
        require(!voteInfo.stopped, "already stopped");
        require(!voteInfo.completed, "already completed");
        require(_nft.length == _nftId.length, "invalid nft info");
        if (voteInfo.targeting) {
            uint32 verified = 0;
            for (uint256 i = 0; i < _historyList.length; i++) {
                bool result = vote.verifyHistoryRoot(
                    _voter,
                    _historyList[i],
                    _historyProof[i]
                );
                if (result) {
                    verified++;
                }
                if (!voteInfo.condition && !result) {
                    revert("failed to verify history");
                }
            }
            for (uint256 i = 0; i < _traitList.length; i++) {
                bool result = vote.verifyTraitRoot(
                    keccak256(abi.encodePacked(_traitNfts[i])),
                    _traitList[i],
                    _traitProof[i]
                );
                if (result) {
                    verified++;
                }
                if (!voteInfo.condition && !result) {
                    revert("failed to verify trait");
                }
            }
            for (uint256 i = 0; i < _nft.length; i++) {
                bool result = vote.verifyNftOwner(_voter, _nft[i], _nftId[i]);
                if (result) {
                    verified++;
                }
                if (!voteInfo.condition && !result) {
                    revert("failed to verify nft owner");
                }
            }
            if (verified == uint32(0)) {
                revert("failed to verify all conditions");
            }
        }
        if (!voteInfo.zkp) {
            require(
                voteInfo.paiedReward < voteInfo.totalReward,
                "over reward money"
            );
        } else {
            require(_zkpProof.length == 10, "invalid arguments");
            uint256 nullifierHash = _zkpProof[0];
            uint256 root = _zkpProof[1];
            uint[2] memory proof_a = [_zkpProof[2], _zkpProof[3]];
            uint[2][2] memory proof_b = [
                [_zkpProof[4], _zkpProof[5]],
                [_zkpProof[6], _zkpProof[7]]
            ];
            uint[2] memory proof_c = [_zkpProof[8], _zkpProof[9]];
            _nullify(
                bytes32(nullifierHash),
                bytes32(root),
                proof_a,
                proof_b,
                proof_c
            );
        }

        vote.execute(_voter, _result);

        voteInfo = vote.get();
        if (!voteInfo.zkp) {
            if (
                (voteInfo.paiedReward == voteInfo.totalReward) ||
                (voteInfo.totalSupply == voteInfo.count)
            ) {
                vote.complete(voteInfo.owner);
                emit Complete(voteInfo.name);
            }
        } else {
            if (voteInfo.totalSupply == voteInfo.count) {
                vote.complete(voteInfo.owner);
                emit Complete(voteInfo.name);
            }
        }
        emit Execute(voteInfo.ca, _voter);
    }

    /// The stop function stops the normal or zkp vote.
    /// @param _hash The hash parameter is the hash of the vote to be stopped.
    function stop(uint256 _hash) public {
        IVote vote = getVote(_hash);
        IVote.Info memory voteInfo = vote.get();
        require(!voteInfo.completed, "already completed");

        vote.stop(msg.sender);

        emit Stop(voteInfo.name);
    }

    /// The complete function completes the normal or zkp vote.
    /// @param _hash The hash parameter is the hash of the vote to be completed.
    function complete(uint256 _hash) public {
        IVote vote = getVote(_hash);
        IVote.Info memory voteInfo = vote.get();
        require(!voteInfo.stopped, "already stopped");
        vote.complete(msg.sender);
        emit Complete(voteInfo.name);
    }

    /// The refund function refunds the normal or zkp vote.
    /// @param _hash The hash parameter is the hash of the vote to be refunded.
    function refund(uint256 _hash) public payable {
        IVote vote = getVote(_hash);
        IVote.Info memory voteInfo = vote.get();
        require(voteInfo.stopped, "must be stopped");
        require(!voteInfo.completed, "already completed");
        require(!voteInfo.zkp, "zkp vote doesn't have any reward");
        vote.refund(msg.sender);
        voteInfo = vote.get();
        emit Refund(voteInfo.name, voteInfo.refundedReward);
    }

    /// The refundBulk function refunds all votes in the hashList at once.
    /// @param _hashList The hashList parameter is the list of hash for vote to be refunded at once.
    function refundBulk(uint256[] memory _hashList) public payable {
        for (uint i = 0; i < _hashList.length; i++) {
            IVote vote = getVote(_hashList[i]);
            IVote.Info memory voteInfo = vote.get();
            if (!voteInfo.zkp && !voteInfo.completed) {
                if (voteInfo.stopped) {
                    refund(_hashList[i]);
                } else {
                    complete(_hashList[i]);
                }
            }
        }
    }

    /// The getVoteInfo function gives the information for vote.
    /// @param _hash The hash parameter is the hash of the vote.
    function getVoteInfo(
        uint256 _hash
    ) public view returns (IVote.Info memory) {
        IVote vote = getVote(_hash);
        return vote.get();
    }

    /// The getVoteList function gives the information of the vote registered.
    function getVoteList() public view onlyOwner returns (uint256[] memory) {
        return voteList;
    }
}
