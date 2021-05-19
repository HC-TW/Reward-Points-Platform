// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.8.0;

import "./Context.sol";

contract Credit is Context {
    struct loanRecord {
        // address borrower;
        // address bank;
        uint256 loanAmount;
        uint256 pointsAmount;
        uint256 dueDate;
        uint16 annualInterestRate; // This value should be divided by 1000. Ex: 3% = 30 / 1000
        uint256 loanBalance;
        string option; // Loan case or something else
    }

    struct keyList {
        address[] keys;
        mapping(address => bool) existing;
    }

    address public _owner;
    address public _BankLiabilityAddr;
    C_RPToken private rp;

    mapping(address => mapping(address => loanRecord[])) _loanRecords;
    mapping(address => keyList) _bankToBorrowers;

    event Loan(
        address indexed borrower,
        address indexed bank,
        uint256 loanAmount,
        uint256 pointsAmount,
        uint256 dueDate,
        uint16 annualInterestRate,
        uint256 loanBalance
    );

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
        uint16 annualInterestRate,
        string memory option
    ) public onlyBank {
        uint256 dueDate = block.timestamp + 30 days;
        _loanRecords[_msgSender()][borrower].push() = loanRecord(
            loanAmount,
            pointsAmount,
            dueDate,
            annualInterestRate,
            loanAmount,
            option
        );
        if (!_bankToBorrowers[_msgSender()].existing[borrower]) {
            _bankToBorrowers[_msgSender()].keys.push(borrower);
            _bankToBorrowers[_msgSender()].existing[borrower] = true;
        }
        rp.deliver(borrower, pointsAmount);

        emit Loan(borrower, _msgSender(), loanAmount, pointsAmount, dueDate, annualInterestRate, loanAmount);
    }

    function changeLoanLender(address oldBank, address newBank) public {
        require(_msgSender() == _owner || _msgSender() == _BankLiabilityAddr);
        address[] memory keys = _bankToBorrowers[oldBank].keys;
        for (uint256 i = 0; i < keys.length; i++) {
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
