// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import "34_ERC721/IERC165.sol";
//抽象了EIP1155所实现的功能
interface IERC1155 is IERC165 {
    //单代币转账接收 操作地址 把代币从from转给to id为代币的唯一标识
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    //多代币转账接收
    event TransferBatch(address indexed operator,address indexed from,address indexed to,uint256[] id,uint256[] value);
    //批量授权 从account授权给operator
    event ApprovalForAll(address indexed account,address indexed operator,bool approved);
    //当编号为id的代币的URI发生改变 
    //URI指向的是一个存储在互联网上的JSON文件，其中描述了这个NFT的名称、描述、图像链接和属性。
    event URI(string value,uint256 indexed id);
    //查询账户单个代币余额
    function balanceOf(address account,uint256 id) external view returns(uint256);
    //批量查询
    function balanceOfBatch(address[] calldata account,uint256[] calldata id) external view returns(uint256[] memory);
    //调用此函数的调用者的代币授权给operator 批量授权
    function setApprovalForAll(address operator,bool approved) external;
    //检查是否授权
    function isApprovedForAll(address account,address operator) external view returns (bool);
    //安全转账
    function safeTransferFrom(address from,address to,uint256 id,uint256 amount,bytes calldata data) external;
    //批量安全转账
    function safeBatchTransferFrom(address from,address to,uint256[] calldata id,uint256[] calldata amount,bytes calldata data) external; 
}