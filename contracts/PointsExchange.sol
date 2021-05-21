// "SPDX-License-Identifier: UNLICENSED"

pragma solidity ^0.8.0;

import "./Context.sol";

contract PointsExchange is Context {
    PE_RPToken private _rp;
    mapping(address => string) _exchangeRates; // Existing points issuer's address => 100 
                                               // means 100 xx points -> 1 rp 

    event ChangeExchangeRate(address bank, string rate);

    modifier onlyBank() {
        require(_rp._banks(_msgSender()), "You are not a bank");
        _;
    }

    constructor(address RPTokenAddr) {
        _rp = PE_RPToken(RPTokenAddr);
    }

    function changeExchangeRate(string memory rate) public onlyBank {
        _exchangeRates[_msgSender()] = rate;
        emit ChangeExchangeRate(_msgSender(), rate);
    }
}

contract PE_RPToken {
    function _banks(address) public view returns (bool) {}
}
