// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
//透明代理合约 在回调函数中 代理逻辑合约时用的是函数选择器 例如bytes4(keccak256("mint(address)")) 四个字节很有可能冲突
//逻辑合约中的函数和代理合约的可升级函数的选择器重复时 会造成错误

contract TransparentProxy{
     address implementation; // logic合约地址
    address admin; // 管理员
    string public words; // 字符串，可以通过逻辑合约的函数改变

    constructor(address _implementation){
        admin = msg.sender;
        implementation = _implementation;
    }
    fallback() external payable {
        require(msg.sender != admin);
        (bool success, bytes memory data) = implementation.delegatecall(msg.data);
    }
     function upgrade(address newImplementation) external {
        if (msg.sender != admin) revert();
        implementation = newImplementation;
    }
}
// 旧逻辑合约
contract Logic1 {
    // 状态变量和proxy合约一致，防止插槽冲突
    address public implementation; 
    address public admin; 
    string public words; // 字符串，可以通过逻辑合约的函数改变

    // 改变proxy中状态变量，选择器： 0xc2985578
    function foo() public{
        words = "old";
    }
}

// 新逻辑合约
contract Logic2 {
    // 状态变量和proxy合约一致，防止插槽冲突
    address public implementation; 
    address public admin; 
    string public words; // 字符串，可以通过逻辑合约的函数改变

    // 改变proxy中状态变量，选择器：0xc2985578
    function foo() public{
        words = "new";
    }
}