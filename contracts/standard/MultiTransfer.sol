// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract MultiTransfer is Ownable {
    using Strings for uint256;

    struct TransferRecipient {
        address payable receiver;
        uint256 amount;
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function multiTransfer(TransferRecipient[] calldata recipients) external virtual onlyOwner payable {
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < recipients.length; i++) {
            totalAmount += recipients[i].amount;
        }
        require(totalAmount == msg.value, "Insufficient amount sent");

        for (uint256 i = 0; i < recipients.length; i++) {
            require(!isContract(recipients[i].receiver), "Cannot send to contract address");

            bool success = recipients[i].receiver.send(recipients[i].amount);
            require(success, string(abi.encodePacked("Transfer failed in ", (i + 1).toString(), "th order")));
        }
    }
}
