// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import "31_ERC20/ERC20.sol";
//线性释放合约
contract TokenVesting {
    //代币释放事件
    event ERC20Released(address indexed token,uint256 amount);
    mapping (address => uint256) public erc20Released;//代币地址 释放数量 记录受益人已领取的代币数量
    address public immutable beneficiary;//受益人地址
    uint256 public immutable start;//归属期起始时间戳
    uint256 public immutable duration;//归属期
    constructor (address beneficiaryAddress,uint256 durationSeconds) {
        require(beneficiaryAddress != address(0));
        beneficiary = beneficiaryAddress;
        start = block.timestamp;
        duration = durationSeconds;
    }
    //释放金额 代币地址
    function release(address token) public {
        uint256 releaseable = vestedAmount(token,uint256(block.timestamp)) - erc20Released[token];
        erc20Released[token] += releaseable;
        IERC20(token).transfer(beneficiary,releaseable);
        emit ERC20Released(token,releaseable);
    }
    //计算释放的金额 代币地址
    function vestedAmount(address token,uint256 timestamp) public view returns(uint256) {
        uint256 total = IERC20(token).balanceOf(address(this)) + erc20Released[token];
        if (timestamp < start) {
            return 0;
        } else if (timestamp >= start && timestamp <= duration + start) {
            return (total *(timestamp - start)) / duration;
        }else {
            return total;
        }
    }
}