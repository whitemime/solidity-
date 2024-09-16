// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
interface IERC20 {
    event Transfer(address indexed from,address indexed to,uint256 value);
    event Approval(address indexed owner,address indexed sender,uint256 value);
    function totalSupply() external view returns(uint256);
    function balanceOf(address amount) external view returns(uint256);
    function transfer(address to,uint256 value) external returns(bool);
    //owner用户授权给sender用户的额度 
    function allowance(address owner,address sender) external view returns(uint256);
    function approval(address to,uint256 value) external returns(bool);
    function transferFrom(address from,address to,uint256 value) external returns(bool);
}