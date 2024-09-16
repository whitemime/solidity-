// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import "./IERC20.sol";
contract ERC20 is IERC20{
    mapping (address => uint256) public override balanceOf;
    mapping (address => mapping (address => uint256)) public override  allowance;
    uint256 public override totalSupply;   // 代币总供给
    string public name;
    string public symbol;
    uint8 public decimals = 18; // 小数位数
    constructor(string memory _name,string memory _symbol){
        name = _name;
        symbol = _symbol;
    } 
    function transfer(address to,uint256 value) public override returns (bool) {
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(msg.sender,to, value);
        return true;
    }
    function approval(address sender,uint256 value) public override returns(bool) {
        allowance[msg.sender][sender] = value;
        emit Approval(msg.sender,sender,value);
        return true;
    }
    function transferFrom(address from,address to,uint256 value) public override returns(bool) {
        allowance[from][msg.sender] -= value;
        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from,to,value);
        return true;
    }
    function mint(uint256 value) external {
        balanceOf[msg.sender] += value;
        totalSupply += value;
        emit Transfer(address(0), msg.sender, value);
    } 
    function burn(uint256 value) external {
        balanceOf[msg.sender] -= value;
        totalSupply -= value;
        emit Transfer(msg.sender,address(0), value);
    }
}