// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import "./IERC165.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC721Metadata.sol";
import "./String.sol";

contract ERC721 is IERC721,IERC721Metadata{
    using Strings for uint256;
    //token名称
    string public override name;
    //token代号
    string public override symbol;
    //tokenid到持有人地址的映射
    mapping (uint => address) private _owner;
    //地址到持仓量的映射
    mapping (address => uint) private _balances;
    //tokenid到授权地址的映射
    mapping (uint => address) private _tokenApprovals;
    //持有地址到被授权地址的批量授权映射
    mapping (address => mapping (address => bool)) private _operatorApprovals;
    error ERC721InvalidReceiver(address receiver);
    //初始化name和symbol
    constructor (string memory _name,string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }
    //实现IERC165接口
    function supportsInterface(bytes4 interfaceId) external pure override  returns(bool){
        return 
            interfaceId == type(IERC721).interfaceId || 
            interfaceId == type(IERC165).interfaceId || 
            interfaceId == type(IERC721Metadata).interfaceId;
    }
    //实现IERC721的balanceof
    function balanceOf(address owner) external view override returns(uint){
        require(owner != address(0),"owner = zero address");
        return _balances[owner];
    }
    //实现IERC721的ownerOf
    function ownerOf(uint tokenid) public view override returns(address owner){
        owner = _owner[tokenid];
        require(owner != address(0),"token does not exist");
    }
     // 实现IERC721的isApprovedForAll，利用_operatorApprovals变量查询owner地址是否将所持NFT批量授权给了operator地址。
    function isApprovalForAll(address owner, address operator)
        external
        view
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }
    //将持有代币全部授权
    function setApprovalForAll(address operator,bool approved) external  override {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }
    //查询tokenid的授权地址
    function getApproved(uint tokenId) external view override returns (address) {
        require(_tokenApprovals[tokenId] != address(0),"token not exist");
        return _tokenApprovals[tokenId];
    }
    //授权函数
    function _approve(address owner,address to,uint tokenid) private {
        _tokenApprovals[tokenid] = to;
        emit Approval(owner,to,tokenid);
    }
    //实现IERC721的approval
    function approve(address to,uint tokenid) external override {
        address owner = _owner[tokenid];
        require(msg.sender == owner || _operatorApprovals[owner][msg.sender],
         "not owner nor approved for all");
         _approve(owner, to, tokenid);
    }
    //查询某个地址是否可以使用tokenid
    function _isApprovedOrOwner(address owner,
    address spender,
    uint tokenid) private view returns (bool) {
        return (spender == owner||
        _tokenApprovals[tokenid] == spender||
        _operatorApprovals[owner][spender]);
    }
    //转账函数
    function _transfer(address owner,address from,address to,uint tokenid) private {
        require(from == owner,"not owner");
        require(to != address(0),"transfer to the zero address");

        _approve(owner,address(0), tokenid);
        _balances[from] -= 1;
        _balances[to] += 1;
        _owner[tokenid] = to;
        emit Transfer(from, to, tokenid);
    }
    //实现IERC721的普通转账函数 不安全
    function transferFrom(
        address from,
        address to,
        uint tokenid
    ) external override {
        address owner = ownerOf(tokenid);
        require(
            _isApprovedOrOwner(owner,msg.sender,tokenid),
            "not owner nor approved"
        );
        _transfer(owner,from,to,tokenid);
    }
    //安全转账
    function _safeTransfer(
        address owner,
        address from,
        address to,
        uint tokenid,
        bytes memory data
    ) private {
        _transfer(owner,from,to,tokenid);
        _checkOnERC721Received(from, to, tokenid, data);
    }
    //实现IERC721安全转账
    function safeTransferFrom(address from,address to,uint tokenid,bytes memory data) public   override  {
        address owner = ownerOf(tokenid);
        require(_isApprovedOrOwner(owner,msg.sender,tokenid),"not owner is approved"); 
        _safeTransfer(owner,from, to, tokenid, data);
    }
    function safeTransferFrom(
        address from,
        address to,
        uint tokenId
    ) external override {
        safeTransferFrom(from, to, tokenId, "");
    }
    //铸造函数
    function _mint(address to,uint tokenid) internal virtual {
        require(to != address(0),"mint to the zero address");
        require(_owner[tokenid] == address(0),"token already minted");
        _balances[to] += 1;
        _owner[tokenid] = to;
        emit Transfer(address(0), to, tokenid);
    }
    //销毁函数
    function _burn(uint tokenid) internal virtual{
        address owner = _owner[tokenid];
        require(owner == msg.sender,"not owner of token");

        _approve(owner, address(0), tokenid);
        _balances[owner] -=  1;
        _owner[tokenid] = address(0);
        emit Transfer(owner, address(0), tokenid);
    }
    // 用于接收地址为合约地址时
    function _checkOnERC721Received(address from,address to,uint256 tokenid,bytes memory data) private {
        //查看是否为合约地址(代码长度是否大于0)
        if (to.code.length > 0){
            try IERC721Receiver(to).onERC721Received(msg.sender,from,tokenid,data) returns (bytes4 result){
                if (result !=IERC721Receiver.onERC721Received.selector){
                    revert ERC721InvalidReceiver(to);
                }
            }catch (bytes memory reason){
                if (reason.length==0){
                    revert ERC721InvalidReceiver(to);
                }else{
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
    }
    /**
     * 实现IERC721Metadata的tokenURI函数，查询metadata。
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_owner[tokenId] != address(0), "Token Not Exist");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * 计算{tokenURI}的BaseURI，tokenURI就是把baseURI和tokenId拼接在一起，需要开发重写。
     * BAYC的baseURI为ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/ 
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }
}