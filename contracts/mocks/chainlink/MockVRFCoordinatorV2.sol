// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";

interface IVRFConsumerV2 {
    function rawFulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) external;
}

contract MockVRFCoordinatorV2 is VRFCoordinatorV2Interface {
    uint256 public nextRequestId = 1;

    function requestRandomWords(
        bytes32,
        uint64,
        uint16,
        uint32,
        uint32
    ) external override returns (uint256 requestId) {
        requestId = nextRequestId++;
    }

    function fulfill(address consumer, uint256 requestId, uint256[] calldata randomWords) external {
        IVRFConsumerV2(consumer).rawFulfillRandomWords(requestId, randomWords);
    }

    // --- Unused interface methods for this test harness ---
    function createSubscription() external pure override returns (uint64) {
        revert("not implemented");
    }

    function pendingRequestExists(uint64) external pure override returns (bool) {
        revert("not implemented");
    }

    function getRequestConfig() external pure override returns (uint16, uint32, bytes32[] memory) {
        revert("not implemented");
    }

    function requestSubscriptionOwnerTransfer(uint64, address) external pure override {
        revert("not implemented");
    }

    function acceptSubscriptionOwnerTransfer(uint64) external pure override {
        revert("not implemented");
    }

    function addConsumer(uint64, address) external pure override {
        revert("not implemented");
    }

    function removeConsumer(uint64, address) external pure override {
        revert("not implemented");
    }

    function cancelSubscription(uint64, address) external pure override {
        revert("not implemented");
    }

    function getSubscription(uint64)
        external
        pure
        override
        returns (uint96, uint64, address, address[] memory)
    {
        revert("not implemented");
    }
}

