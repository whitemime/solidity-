// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./IERC1155MetadataURI.sol";
import "34_ERC721/IERC165.sol";
import "34_ERC721/String.sol";
contract ERC1155 is IERC165, IERC1155, IERC1155MetadataURI{
    using Strings for uint256;
    //代币的名称和代号
    string public name;
    string public symbol;
    //代币的id 地址 余额
    mapping (uint256=>mapping (address=>uint256)) private _balances;
    //地址 地址 是否授权
    mapping (address=>mapping (address=>bool)) private  _operatorApprovals;
    constructor (string memory _name,string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }
    //实现ERC165标准，声明它支持的接口，供其他合约检查。
    function supportsInterface(bytes4 interfaceId) public view virtual override returns(bool){
        return interfaceId == type(IERC165).interfaceId || interfaceId == type(IERC1155).interfaceId || interfaceId == type(IERC1155MetadataURI).interfaceId;
    }
    //持仓查询 地址 代币id
    function balanceOf(address account,uint256 id) public view virtual override returns (uint256){
        require(account != address(0),"ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }
    //批量持仓查询 地址数组 代币id数组
    function balanceOfBatch(address[] memory accounts,uint256[] memory ids)public view virtual override returns(uint256[] memory){
        require(accounts.length == ids.length,"ERC1155: accounts and ids length mismatch");
        uint256[] memory batchBalances = new uint256[](accounts.length);
        for(uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }
        return batchBalances;
    }
    //批量授权 被授权的账户地址 是否被授权
    function setApprovalForAll(address operator,bool approved) public virtual override {
        require(msg.sender != operator,"ERC1155: setting approval status for self");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender,operator,approved);
    }
    //查询批量授权 代币拥有地址 被授权地址
    function isApprovedForAll(address account,address operator) public view virtual override returns(bool){
        return _operatorApprovals[account][operator];
    }
    //安全转账
    function safeTransferFrom(address from,address to,uint256 id,uint256 amount,bytes memory data) public virtual override {
        address operator = msg.sender;
        //调用该函数的调用者是持有者或者是被授权的
        require(from == operator || isApprovedForAll(from,operator),"ERC1155: transfer from must be owner");
        require(to != address(0),"ERC1155: transfer to must be not zero");
        require(amount <= _balances[id][from],"ERC1155: transfer amount exceeds balance");
        _balances[id][from] = _balances[id][from] - amount;
       // 释放事件
        emit TransferSingle(operator, from, to, id, amount);
        // 安全检查
        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);  
    }
    //安全批量转账
    function safeBatchTransferFrom(
        address from,address to,uint256[] memory ids,uint256[] memory amounts,bytes memory data
    ) public virtual override {
        //函数调用者
        address operator = msg.sender;
        //拥有者是不是函数调用者或者已经授权
        require(from == operator || isApprovedForAll(from,operator),"ERC1155: caller is not token owner nor approved");
        //代币和数量对应
        require(ids.length == amounts.length,"ERC1155: ids and amounts length mismatch");
        require(to != address(0),"ERC1155: transfer to the zero address");
        for(uint256 i = 0;i<ids.length;++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];
            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        }
        emit TransferBatch(operator, from, to, ids, amounts);
        // 安全检查
        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);    
    }
    //铸造 得到代币的地址 数量 代币
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0),"ERC1155: mint to the zero address");
        address operator = msg.sender;
        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }
    //批量铸造
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
         require(to != address(0),"ERC1155: mint to the zero address");
         require(ids.length == amounts.length,"ERC1155: ids and amounts length mismatch");
         address operator = msg.sender;
         for(uint256 i = 0;i < ids.length;++i) {
            _balances[ids[i]][to] += amounts[i];
         }
          emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }
    //销毁 拥有者地址
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0),"ERC1155: burn from the zero address");
        address operator = msg.sender;
        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount,"ERC1155: burn amount exceeds balance");
         _balances[id][from] = fromBalance - amount;
         emit TransferSingle(operator, from, address(0), id, amount);
    }
    //批量销毁
    function _burnBatch(address from,uint256[] memory ids,uint256[] memory amounts) internal virtual {
        require(from != address(0),"ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        address operator = msg.sender;
        for(uint256 i = ids.length - 1 ;i >= 0;--i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];
            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount,"ERC1155: burn amount exceeds balance");
            _balances[id][from] = fromBalance - amount;
           
        } 
         emit TransferBatch(operator, from, address(0), ids, amounts);
    }
    //安全转账检查 操作者地址 拥有者 接受者 代币id 数量 代币信息
    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        //接收者代码长度大于0 为合约地址
        if (to.code.length > 0) {
            //调用合约
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns(bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                } 
            } catch  Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }
    // @dev ERC1155的批量安全转账检查
    function _doSafeBatchTransferAcceptanceCheck(
        address operator,address from,address to,uint256[] memory ids,uint256[] memory amounts,bytes memory data) private {
         //接收者代码长度大于0 为合约地址
         if (to.code.length > 0) {
             try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns(bytes4 response) {
                 if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                     revert("ERC1155: ERC1155Receiver rejected tokens");
                 } 
             } catch  Error(string memory reason) {
                revert(reason);
             } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
             } 
         } 
    }
     /**
     * @dev 返回ERC1155的id种类代币的uri，存储metadata，类似ERC721的tokenURI.
     */
    function uri(uint256 id) public view virtual override returns (string memory) {
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, id.toString())) : "";
    }

    /**
     * 计算{uri}的BaseURI，uri就是把baseURI和tokenId拼接在一起，需要开发重写.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }
}
