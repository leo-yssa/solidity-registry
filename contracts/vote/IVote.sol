//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IVote {
    struct Info {
        address owner;
        address[] nftList;
        string name;
        bool targeting;
        bool condition;
        address ca;
        uint256 balance;
        uint256 count;
        uint256 totalSupply;
        uint256 totalReward;
        uint256 paiedReward;
        uint256 refundedReward;
        uint256 perReward;
        bool completed;
        bool stopped;
        bool zkp;
    }

    function verifyHistoryRoot(
        address _voter,
        address _history,
        bytes32[] memory _historyProof
    ) external view returns (bool);

    function verifyTraitRoot(
        bytes32 _traitLeaf,
        uint256 _trait,
        bytes32[] memory _traitProof
    ) external view returns (bool);

    function verifyNftOwner(
        address _voter,
        address _nft,
        uint256 _nftId
    ) external view returns (bool);

    function execute(address _voter, uint256 _result) external payable;

    function stop(address _owner) external;

    function complete(address _owner) external;

    function refund(address _owner) external payable;

    function get() external view returns (Info memory);
}
