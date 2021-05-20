// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.8.0;

import "./Context.sol";

contract BankLiability is Context {
    address public _owner;
    address public _RPToken;
    MiniRPToken private rp;
    MiniCredit private credit;
    int256 public _totalLiability;

    mapping(address => int256) public _liabilities;
    mapping(address => mapping(address => uint256)) private _confirmRemittance;

    event TransferRequest(
        address indexed sender,
        address indexed recipient,
        uint256 amount
    );
    event RevokeRequest(address indexed sender, address indexed recipient);
    event Accept(
        address indexed sender,
        address indexed recipient,
        uint256 amount
    );

    modifier onlyOwner() {
        require(_msgSender() == _owner);
        _;
    }

    modifier onlyBank() {
        require(rp._banks(_msgSender()), "You are not a bank");
        _;
    }

    constructor(address RPTokenAddr) {
        _owner = _msgSender();
        _RPToken = RPTokenAddr;
        rp = MiniRPToken(RPTokenAddr);
    }

    function loadCredit(address addr) public onlyOwner {
        credit = MiniCredit(addr);
    }

    function transferRequest(address recipient, uint256 amount)
        public
        onlyBank
        returns (bool)
    {
        require(
            rp._banks(recipient),
            "Liability: You can only request to transfer liability to banks"
        );
        require(amount != 0, "Liability: transfer zero amount");
        require(
            _confirmRemittance[_msgSender()][recipient] == 0,
            "Liability: You cannot send multiple requests to the same bank"
        );
        _confirmRemittance[_msgSender()][recipient] = amount;

        emit TransferRequest(_msgSender(), recipient, amount);
        return true;
    }

    function revokeRequest(address recipient) public onlyBank returns (bool) {
        require(
            rp._banks(recipient),
            "Liability: You can only revoke request to banks"
        );
        require(
            _confirmRemittance[_msgSender()][recipient] > 0,
            "Liability: You cannot revoke requests before sending requests"
        );
        _confirmRemittance[_msgSender()][recipient] = 0;

        emit RevokeRequest(_msgSender(), recipient);
        return true;
    }

    function accept(address sender) public onlyBank returns (bool) {
        require(
            rp._banks(sender),
            "Liability: You can only accept the request from banks"
        );
        uint256 amount = _confirmRemittance[sender][_msgSender()];
        require(
            amount != 0,
            "Liability: The sender didn't send the transfer request"
        );
        _liabilities[sender] += int256(amount);
        _liabilities[_msgSender()] -= int256(amount);
        delete _confirmRemittance[sender][_msgSender()];

        credit.changeLoanLender(sender, _msgSender());
        
        emit Accept(_msgSender(), sender, amount);
        return true;
    }

    function increaseLiability(address addr, uint256 amount) public {
        require(_msgSender() == _owner || _msgSender() == _RPToken);
        require(amount != 0, "Liability: increase zero amount");
        _liabilities[addr] -= int256(amount);
        _totalLiability -= int256(amount);
    }

    function decreaseLiability(address addr, uint256 amount) public {
        require(_msgSender() == _owner || _msgSender() == _RPToken);
        require(amount != 0, "Liability: decrease zero amount");
        _liabilities[addr] += int256(amount);
        _totalLiability += int256(amount);
    }
}

contract MiniRPToken {
    function _banks(address) public view returns (bool) {}
}

contract MiniCredit {
    function changeLoanLender(address, address) public {}
}
