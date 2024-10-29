// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
//代币锁合约 在DEX中 项目方提出一款新代币 吸引用户进行质押 为了延缓项目方跑路 过一定时间才能释放
import "31_ERC20/IERC20.sol";
import "31_ERC20/ERC20.sol";

contract TokenLocker{
    //锁仓开始事件 受益人地址 代币地址 开始时间 结束时间
    event TokenLockerStart(address indexed beneficiary,address indexed token,uint256 startTime,uint256 lockTime);
    //代币释放事件 受益人地址 代币地址 释放的时间 释放的数量
    event Release(address indexed beneficiary,address indexed token,uint256 releaseTime,uint256 amount);

    IERC20 public immutable token;//代币合约地址
    address public immutable beneficiary;//受益人地址
    uint256 public immutable lockTime;//锁仓时间
    uint256 public immutable startTime;//开始时间

    constructor (IERC20 _token,address _beneficiary,uint256 _lockTime) {
        require(_lockTime > 0);
        token = _token;
        beneficiary = _beneficiary;
        lockTime = _lockTime;
        startTime = block.timestamp;
        emit TokenLockerStart(_beneficiary, address(_token), block.timestamp, _lockTime);
    }
    function release() public {
        require(block.timestamp >= startTime + lockTime);
        uint256 amount = token.balanceOf(address(this));
        require(amount > 0);
        token.transfer(beneficiary, amount);
        emit Release(msg.sender, address(token), block.timestamp, amount);
    }
}