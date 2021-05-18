// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.8.0;

import "./Context.sol";

contract Credit is Context {
    struct loanRecord {
        // address borrower;
        // address bank;
        uint256 loanAmount;
        uint256 pointsAmount;
        uint256 timestamp;
        uint16 annualInterestRate; // This value should be divided by 1000. Ex: 3% = 30 / 1000
        uint256 loanBalance;
    }

    struct keyList {
        address[] keys;
        mapping (address => bool) existing;
    }

    address public _owner;
    address public _BankLiabilityAddr;
    C_RPToken private rp;

    mapping(address => mapping(address => loanRecord[])) _loanRecords;
    mapping(address => keyList) _bankToBorrowers;

    modifier onlyOwner() {
        require(_msgSender() == _owner, "You are not a contract owner");
        _;
    }

    modifier onlyBank() {
        require(rp._banks(_msgSender()), "You are not a bank");
        _;
    }

    constructor(address RPTokenAddr) {
        _owner = _msgSender();
        rp = C_RPToken(RPTokenAddr);
    }

    function setBankLiabilityAddr(address addr) public onlyOwner {
        _BankLiabilityAddr = addr;
    }

    function loan(
        address borrower,
        uint256 loanAmount,
        uint256 pointsAmount,
        uint16 annualInterestRate
    ) public onlyBank {
        _loanRecords[_msgSender()][borrower].push() = loanRecord(
            loanAmount,
            pointsAmount,
            block.timestamp,
            annualInterestRate,
            loanAmount
        );
        if (!_bankToBorrowers[_msgSender()].existing[borrower])
        {
            _bankToBorrowers[_msgSender()].keys.push(borrower);
            _bankToBorrowers[_msgSender()].existing[borrower] = true;
        }
        rp.deliver(borrower, pointsAmount);
    }

    function changeLoanLender(address oldBank, address newBank) public {
        require(_msgSender() == _owner || _msgSender() == _BankLiabilityAddr);
        address[] memory keys = _bankToBorrowers[oldBank].keys;
        for (uint i = 0; i < keys.length; i++) {
            _loanRecords[newBank][keys[i]] = _loanRecords[oldBank][keys[i]];
            delete _loanRecords[oldBank][keys[i]];
        }
        delete _bankToBorrowers[oldBank];
    }
}

contract C_RPToken {
    function _banks(address) public view returns (bool) {}
    function deliver(address, uint256) public returns (bool) {}
}
