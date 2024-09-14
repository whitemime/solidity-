// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

//输入要查询的接口id 如果合约实现了某接口 返回true
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns(bool);
}