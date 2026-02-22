// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./StdErrors.sol";

contract MultiTransfer is Ownable {
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
        if (totalAmount != msg.value) revert StdErrors.IncorrectPayment(totalAmount, msg.value);

        for (uint256 i = 0; i < recipients.length; i++) {
            if (isContract(recipients[i].receiver)) revert StdErrors.RecipientIsContract(recipients[i].receiver);

            (bool ok, ) = recipients[i].receiver.call{value: recipients[i].amount}("");
            if (!ok) {
                revert StdErrors.EthTransferFailed(recipients[i].receiver, recipients[i].amount);
            }
        }
    }
}
