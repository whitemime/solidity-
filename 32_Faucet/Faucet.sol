// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import "31_ERC20/IERC20.sol";
contract ERC20 is IERC20{
    mapping (address => uint256) public override balanceOf;
    mapping (address => mapping (address => uint256)) public override  allowance;
     uint256 public override totalSupply;   // 代币总供给
     string public name;
     string public symbol;
     uint8 public decimals = 18; // 小数位数
     constructor(string memory _name, string memory _symbol)  {
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

//水龙头合约
contract Faucet{
    //每个账户可领100个
    uint256 public a = 100;
    //代币合约地址
    address public contractAddr;
    //记录领过的地址
    mapping (address => bool) public reAddr;
    event Send(address indexed to,uint256 amount);
    constructor(address addr) {
        contractAddr = addr;
    }
    function faucet() external {
        require(reAddr[msg.sender]==true);
        IERC20 ierc = IERC20(contractAddr);
        require(ierc.balanceOf(address(this))>=a);
        ierc.transfer(msg.sender,a);
        reAddr[msg.sender] = true;
        emit Send(msg.sender,a);
    }
}