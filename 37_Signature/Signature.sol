// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import "34_ERC721/ERC721.sol";
//数字签名
library ECDSA {
    //验证签名 输入消息哈希 签名 公钥
    function verify(bytes32 _msghash,bytes memory _signature, address _signer) internal pure returns(bool) {
        return recoverSigner(_msghash, _signature) == _signer;
    }
    //用消息哈希和签名恢复签名地址（公钥好像可以算地址）
    function recoverSigner(bytes32 _msghash,bytes memory _signature) internal pure returns(address) {
        //检查签名长度 r,s,v 长度一共65
        require(_signature.length == 65);
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(_signature, 0x20))
            s := mload(add(_signature, 0x40))
            v := byte(0, mload(add(_signature, 0x60)))
        }
        // 使用ecrecover(全局函数)：利用 msgHash 和 r,s,v 恢复 signer 地址
        return ecrecover(_msghash, v, r,s);
    }
    function toEthSignedMessageHash(bytes32 hash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32",hash));
    }
}    
//数字签名发放白名单 项目方用自己账户在链下对消息进行签名 白名单内的用户用智能合约验证
contract SignatureNFT is ERC721{
    address immutable public signer;//项目方公钥地址
    mapping (address => bool) public  mintedAddress; 
    constructor(string memory _name, string memory _symbol, address _signer) ERC721(_name, _symbol){
        signer = _signer;  //项目方公钥地址
    }  
    //打包消息
    function getMessageHash(address _addr,uint256 _tokenId) public pure returns(bytes32){
        return keccak256(abi.encodePacked(_addr, _tokenId));
    }
    //验证调用
    function verify(bytes32 _msghash,bytes memory _signer) public view returns(bool) {
        return ECDSA.verify(_msghash,_signer,signer);
    }
    //验证并且铸造 传入的是用户地址 项目方的签名 用户想铸造的代币
    function mint(address addr,bytes memory _signature,uint256 tokenid) external {
        //打包消息
        bytes32 _msghash = getMessageHash(addr, tokenid);
        //换成以太坊格式
        bytes32 _ethSignedMessageHash = ECDSA.toEthSignedMessageHash(_msghash);    
        require(verify(_ethSignedMessageHash, _signature), "Invalid signature");//验证签名
        require(!mintedAddress[addr]);
        mintedAddress[addr] = true;
        _mint(addr, tokenid);
    }
}