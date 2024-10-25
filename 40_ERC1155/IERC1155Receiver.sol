// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import "34_ERC721/IERC165.sol";
//接收ERC1155的安全转账 必须实现这个接口合约
interface IERC1155Receiver is IERC165 {
    //单个代币转账接收函数
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);
    //批量安全转账接收函数
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}