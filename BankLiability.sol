pragma solidity ^0.8.0;

import "./Context.sol";

contract BankLiability is Context{
    address public _owner;
    
    int256 public totalLiability;
    
    mapping (address => bool) _banks;
    mapping (address => int256) public _liabilities;
    mapping (address => mapping (address => uint256)) _confirmRemittance;
    
    event TransferRequest(address indexed sender, address indexed recipient, uint256 amount);
    event Confirm(address indexed sender, address indexed recipient, uint256 amount);

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
        require(recipient != address(0), "Liability: transfer to the zero address");
        require(amount != 0, "Liability: transfer zero amount");
        _confirmRemittance[_msgSender()][recipient] = amount;
        

        emit TransferRequest(_msgSender(), recipient, amount);
        return true;
    }
    
    function confirm(address sender) public onlyBank returns (bool) {
        require(sender != address(0), "Liability: transfer to the zero address");
        uint256 amount = _confirmRemittance[sender][_msgSender()];
        require(amount != 0, "Liability: The sender didn't send the transfer Request");
        _liabilities[sender] += int256(amount);
        _liabilities[_msgSender()] -= int256(amount);

        emit Confirm(_msgSender(), sender, amount);
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
