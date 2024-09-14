// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import "./IERC165.sol";

interface IERC721 is IERC165{
    //转账事件
    event Transfer(address indexed from,address indexed to,uint256 indexed tokenid);
    //单个授权事件
    event Approval(address indexed owner,address indexed approved,uint256 indexed tokenid);
    //批量授权
    event ApprovalForAll(address indexed owner,address indexed operator,bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenid) external view returns(address owner);
    function transferFrom(address from,address to,uint256 tokenid) external;
    function safeTransferFrom(address from,address to,uint256 tokenid) external ;
     function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
    function approve(address to,uint256 tokenid) external;
    function getApproved(uint256 tokenid) external view returns(address operator);
    function setApprovalForAll(address operator,bool _operator) external ;
    function isApprovalForAll(address owner,address operator) external view returns(bool);
}