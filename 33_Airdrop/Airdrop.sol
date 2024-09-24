// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import "31_ERC20/IERC20.sol";
contract ERC20 is IERC20{
    mapping (address => uint256) public override balanceOf;
    mapping (address => mapping (address => uint256)) public override allowance;
    uint256 public override totalSupply;
    string public name;
    string public symbol;
    uint8 public decimals = 18; // 小数位数
    constructor(string memory _name,string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }
    function transfer(address to,uint256 value) public override returns(bool) {
        balanceOf[msg.sender] -= value; // 转出
        balanceOf[to] += value; // 转入
        emit Transfer(msg.sender,to,value);
        return true ;
    }
    //授权 调用者给sender账户授权
    function approval(address sender,uint256 value) public override returns(bool) {
        allowance[msg.sender][sender] = value;
        emit Approval(msg.sender,sender,value);
        return true;
    }
    //授权转账 from账户给to账户转账 转账的部分从调用者的授权中减
    function transferFrom(address from,address to,uint256 value) public override returns(bool) {
        allowance[from][msg.sender] -= value;
        balanceOf[from] -= value; // 转出
        balanceOf[to] += value; // 转入
        emit Transfer(from,to,value);
        return true ;
    }
    //铸币
    function mint(uint256 value) external {
        balanceOf[msg.sender] += value;
        totalSupply += value;
        emit Transfer(address(0),msg.sender,value);
    }
    //销毁
    function burn(uint256 value) external {
        balanceOf[msg.sender] -= value;
        totalSupply -= value;
        emit Transfer(msg.sender,address(0),value);
    }
}
//空投合约
contract Airdrop{
    mapping (address => uint256) failTransferList;
    function getSum(uint[] calldata _sum) public pure returns(uint sum) {
        for (uint i = 0; i < _sum.length; i++) {
            sum += _sum[i]; // 累加
        } // 循环结束 返回
    }
    //发送代币空投函数
    function multiTransferToken(address token,address[] calldata _addr,uint[] calldata _amount) external {
        require(_addr.length == _amount.length);
        IERC20 ierc = IERC20(token);
        uint _amountsum = getSum(_amount);
        require(ierc.allowance(msg.sender, address(this)) >= _amountsum);
        for (uint i = 0; i < _addr.length; i++) {
            ierc.transferFrom(msg.sender,_addr[i], _amount[i]); // 转账
        } // 循环结束 返回
    }
    function multiTransferETH(address[] calldata _addr,uint[] calldata _amount) public payable  {
        require(_addr.length == _amount.length);
        uint _amountsum = getSum(_amount);
        require(msg.value == _amountsum);
        for (uint i = 0;i < _addr.length;i++) {
            (bool success,) = _addr[i].call{value: _amount[i]}(""); // 转账
            if (!success) {
                failTransferList[address(_addr[i])] = _amount[i]; // 记录失败的地址
            }
        }
    }
    //重试失败空投
    function withdrawFromFailList(address _to) public {
        uint failamount = failTransferList[msg.sender];
        require(failamount > 0);
        failTransferList[msg.sender] = 0;
        (bool success,) = _to.call{value:failamount}("");
        require(success);
    }
}