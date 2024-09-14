// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
//ERC721接口接收者 必须实现这个接口来进行安全转账接受ERC721
interface IERC721Receiver {
    function onERC721Received(address operator,address from,uint256 tokenid,bytes calldata data) external returns(bytes4);
}