// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PayableReceiver {
    event Received(address indexed from, uint256 amount);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}

