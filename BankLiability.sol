pragma solidity ^0.8.0;

import "./Context.sol";

contract BankLiability is Context{
    address public _owner;
    
    int256 public totalLiability;
    
    mapping (address => bool) public _banks;
    mapping (address => int256) public _liabilities;
    mapping (address => mapping (address => uint256)) _confirmRemittance;
    
    event TransferRequest(address indexed sender, address indexed recipient, uint256 amount);
    event RevokeRequest(address indexed sender, address indexed recipient);
    event Accept(address indexed sender, address indexed recipient, uint256 amount);

    modifier onlyOwner() {
        require(_msgSender() == _owner);
        _;
    }
    
    modifier onlyBank() {
        require(_banks[_msgSender()]);
        _;
    }
    
    constructor() {
        _owner = _msgSender();
    }
    
    function transferRequest(address recipient, uint256 amount) public onlyBank returns (bool) {
        require(_banks[recipient], "Liability: You can only request to transfer liability to banks");
        require(amount != 0, "Liability: transfer zero amount");
        require(_confirmRemittance[_msgSender()][recipient] == 0, "Liability: You cannot send multiple requests to the same bank");
        _confirmRemittance[_msgSender()][recipient] = amount;
        
        emit TransferRequest(_msgSender(), recipient, amount);
        return true;
    }
    
    function revokeRequest(address recipient) public onlyBank returns (bool) {
        require(_banks[recipient], "Liability: You can only revoke request to banks");
        require(_confirmRemittance[_msgSender()][recipient] > 0, "Liability: You cannot revoke requests before sending requests");
        _confirmRemittance[_msgSender()][recipient] = 0;
        
        emit RevokeRequest(_msgSender(), recipient);
        return true;
    }
    
    function accept(address sender) public onlyBank returns (bool) {
        require(_banks[sender], "Liability: You can only accept the request from banks");
        uint256 amount = _confirmRemittance[sender][_msgSender()];
        require(amount != 0, "Liability: The sender didn't send the transfer request");
        _liabilities[sender] += int256(amount);
        _liabilities[_msgSender()] -= int256(amount);
        delete _confirmRemittance[sender][_msgSender()];
        
        emit Accept(_msgSender(), sender, amount);
        return true;
    }
    
    function addBank(address addr) public onlyOwner {
        _banks[addr] = true;
    }
    
    function removeBank(address addr) public onlyOwner {
        delete _banks[addr];
    }
    
    function increaseLiability(address addr, uint256 amount) public onlyOwner {
        require(amount != 0, "Liability: increase zero amount");
        _liabilities[addr] -= int256(amount);
        totalLiability -= int256(amount);
    }
    
    function decreaseLiability(address addr, uint256 amount) public onlyOwner {
        require(amount != 0, "Liability: decrease zero amount");
        _liabilities[addr] += int256(amount);
        totalLiability += int256(amount);
    }
    
}
