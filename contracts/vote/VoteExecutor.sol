//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IVote.sol";
import "../zk-merkle-tree/ZKTree.sol";

interface IVoteFactory {
    function getVoteAddress(uint256 _hash) external view returns (address);
}

/// @notice Vote executor/manager. Works with `VoteFactory` as a vote factory.
contract VoteExecutor is ZKTree, Ownable {
    IVoteFactory public immutable factory;

    event Execute(address vote, address voter);
    event Complete(string name);
    event Stop(string name);
    event Refund(string name, uint256 balance);

    constructor(
        address factory_,
        uint32 _levels,
        IHasher _hasher,
        IVerifier _verifier
    ) ZKTree(_levels, _hasher, _verifier) {
        require(factory_ != address(0), "factory cannot be zero");
        factory = IVoteFactory(factory_);
        transferOwnership(msg.sender);
    }

    /// @notice Registers a commitment for ZKP votes.
    function registCommitment(uint256 _commitment) public onlyOwner {
        _commit(bytes32(_commitment));
    }

    function _getVote(uint256 _hash) private view returns (IVote) {
        address voteAddr = factory.getVoteAddress(_hash);
        require(voteAddr != address(0), "not registed vote");
        return IVote(voteAddr);
    }

    /// @notice Executes the normal or zkp vote.
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
        IVote vote = _getVote(_hash);
        IVote.Info memory voteInfo = vote.get();
        require(!voteInfo.stopped, "already stopped");
        require(!voteInfo.completed, "already completed");
        require(_nft.length == _nftId.length, "invalid nft info");
        if (voteInfo.targeting) {
            uint32 verified = 0;
            for (uint256 i = 0; i < _historyList.length; i++) {
                bool result = vote.verifyHistoryRoot(_voter, _historyList[i], _historyProof[i]);
                if (result) verified++;
                if (!voteInfo.condition && !result) revert("failed to verify history");
            }
            for (uint256 i = 0; i < _traitList.length; i++) {
                bool result = vote.verifyTraitRoot(
                    keccak256(abi.encodePacked(_traitNfts[i])),
                    _traitList[i],
                    _traitProof[i]
                );
                if (result) verified++;
                if (!voteInfo.condition && !result) revert("failed to verify trait");
            }
            for (uint256 i = 0; i < _nft.length; i++) {
                bool result = vote.verifyNftOwner(_voter, _nft[i], _nftId[i]);
                if (result) verified++;
                if (!voteInfo.condition && !result) revert("failed to verify nft owner");
            }
            if (verified == uint32(0)) revert("failed to verify all conditions");
        }
        if (!voteInfo.zkp) {
            require(voteInfo.paiedReward < voteInfo.totalReward, "over reward money");
        } else {
            require(_zkpProof.length == 10, "invalid arguments");
            uint256 nullifierHash = _zkpProof[0];
            uint256 root = _zkpProof[1];
            uint[2] memory proof_a = [_zkpProof[2], _zkpProof[3]];
            uint[2][2] memory proof_b = [[_zkpProof[4], _zkpProof[5]], [_zkpProof[6], _zkpProof[7]]];
            uint[2] memory proof_c = [_zkpProof[8], _zkpProof[9]];
            _nullify(bytes32(nullifierHash), bytes32(root), proof_a, proof_b, proof_c);
        }

        vote.execute(_voter, _result);

        voteInfo = vote.get();
        if (!voteInfo.zkp) {
            if ((voteInfo.paiedReward == voteInfo.totalReward) || (voteInfo.totalSupply == voteInfo.count)) {
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

    function stop(uint256 _hash) public {
        IVote vote = _getVote(_hash);
        IVote.Info memory voteInfo = vote.get();
        require(!voteInfo.completed, "already completed");

        vote.stop(msg.sender);

        emit Stop(voteInfo.name);
    }

    function complete(uint256 _hash) public {
        IVote vote = _getVote(_hash);
        IVote.Info memory voteInfo = vote.get();
        require(!voteInfo.stopped, "already stopped");
        vote.complete(msg.sender);
        emit Complete(voteInfo.name);
    }

    function refund(uint256 _hash) public payable {
        IVote vote = _getVote(_hash);
        IVote.Info memory voteInfo = vote.get();
        require(voteInfo.stopped, "must be stopped");
        require(!voteInfo.completed, "already completed");
        require(!voteInfo.zkp, "zkp vote doesn't have any reward");
        vote.refund(msg.sender);
        voteInfo = vote.get();
        emit Refund(voteInfo.name, voteInfo.refundedReward);
    }

    function refundBulk(uint256[] memory _hashList) public payable {
        for (uint i = 0; i < _hashList.length; i++) {
            IVote vote = _getVote(_hashList[i]);
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

    function getVoteInfo(uint256 _hash) public view returns (IVote.Info memory) {
        IVote vote = _getVote(_hash);
        return vote.get();
    }
}

