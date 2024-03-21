// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0 <0.9.0;

import "../hts-precompile/HederaResponseCodes.sol";
import "../hts-precompile/IHederaTokenService.sol";
import "../hts-precompile/HederaTokenService.sol";
import "../hts-precompile/ExpiryHelper.sol";
import "../hts-precompile/KeyHelper.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTCreator is ExpiryHelper, KeyHelper, HederaTokenService, Ownable {
    mapping(bytes32 => address) tokenAddress;

    event Create(address tokenAddress);
    event Frozen(address operator, bool frozen);
    event ResponseCode(int responseCode);
    event Transfer(address tokenAddress, address receiver, int64 amount);
    event Mint(int64 newTotalSupply, int64[] serialNumbers);

    constructor() {
        transferOwnership(msg.sender);
    }

    function create(
        string memory name,
        string memory symbol,
        string memory memo,
        int64 maxSupply,
        int64 autoRenewPeriod
    ) external payable onlyOwner returns (address) {
        IHederaTokenService.TokenKey[]
            memory keys = new IHederaTokenService.TokenKey[](3);
        keys[0] = getSingleKey(
            KeyType.SUPPLY,
            KeyValueType.CONTRACT_ID,
            address(this)
        );
        keys[1] = getSingleKey(
            KeyType.FREEZE,
            KeyValueType.INHERIT_ACCOUNT_KEY,
            bytes("")
        );
        keys[2] = getSingleKey(
            KeyType.WIPE,
            KeyValueType.INHERIT_ACCOUNT_KEY,
            bytes("")
        );

        IHederaTokenService.HederaToken memory token;
        token.name = name;
        token.symbol = symbol;
        token.memo = memo;
        token.treasury = address(this);
        token.tokenSupplyType = true;
        token.maxSupply = maxSupply;
        token.tokenKeys = keys;
        token.freezeDefault = false;
        token.expiry = createAutoRenewExpiry(address(this), autoRenewPeriod); // Contract auto-renews the token 90days

        (int responseCode, address createdToken) = HederaTokenService
            .createNonFungibleToken(token);

        if (responseCode != HederaResponseCodes.SUCCESS) {
            revert("Failed to create non-fungible token");
        }

        tokenAddress[keccak256(bytes(name))] = createdToken;
        emit Create(createdToken);
        return createdToken;
    }

    function mint(
        address token,
        bytes[] memory metadata
    )
        public
        onlyOwner
        returns (int responseCode, int64 newTotalSupply, int64 serial)
    {
        int64[] memory serialNumbers;
        (responseCode, newTotalSupply, serialNumbers) = mintToken(
            token,
            0,
            metadata
        );
        if (responseCode != HederaResponseCodes.SUCCESS) {
            revert("Failed to mint non-fungible token");
        }
        emit Mint(newTotalSupply, serialNumbers);
        serial = serialNumbers[0];
    }

    function transfer(
        address token,
        address receiver,
        int64 serial
    ) public returns (int responseCode) {
        responseCode = transferNFT(token, address(this), receiver, serial);

        if (responseCode != HederaResponseCodes.SUCCESS) {
            revert("Failed to transfer non-fungible token");
        }

        emit Transfer(token, receiver, 0);

        responseCode = freezeToken(token, receiver);

        if (responseCode != HederaResponseCodes.SUCCESS) {
            revert("Failed to freeze");
        }
        emit Frozen(receiver, true);
    }

    function wipe(
        address token,
        address account
    ) public onlyOwner returns (int responseCode) {
        responseCode = unfreezeToken(token, account);

        if (responseCode != HederaResponseCodes.SUCCESS) {
            revert("Failed to Unfreeze");
        }

        emit Frozen(account, false);

        int64[] memory serials = new int64[](1);
        responseCode = HederaTokenService.wipeTokenAccountNFT(
            token,
            account,
            serials
        );
        emit ResponseCode(responseCode);

        if (responseCode != HederaResponseCodes.SUCCESS) {
            revert();
        }
    }

    function getTokenAddress(
        string memory name
    ) public view onlyOwner returns (address) {
        return tokenAddress[keccak256(bytes(name))];
    }

    function isFrozenPublic(
        address token,
        address account
    ) public onlyOwner returns (int responseCode, bool frozen) {
        (responseCode, frozen) = HederaTokenService.isFrozen(token, account);
        emit ResponseCode(responseCode);

        if (responseCode != HederaResponseCodes.SUCCESS) {
            revert();
        }
    }
}
