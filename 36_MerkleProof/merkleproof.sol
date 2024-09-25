// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import "34_ERC721/ERC721.sol";
library MerkleProof {
    //计算后是否等于根哈希
    function verify(bytes32[] memory proof,bytes32 leaf,bytes32 root) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }
    //根据全节点给出的路径计算
    function processProof(bytes32[] memory proof,bytes32 leaf) internal pure returns (bytes32)  {
        bytes32 cnt = leaf;
        for (uint i = 0;i < proof.length;i++) {
            cnt = hashPair(cnt, proof[i]);
        }
        return cnt;
    }
    //严格排序
    function hashPair(bytes32 a,bytes32 b) internal pure returns (bytes32)   {
        return a < b ?  keccak256(abi.encodePacked(a, b)) :  keccak256(abi.encodePacked(b, a));
    }
}
//发送NFT白名单
contract merkleTree is ERC721 {
    bytes32 immutable public root;
    mapping (address => bool)  public mintedAddress;
    constructor(string memory _name,string memory _symbol,bytes32 merklehash) ERC721(_name, _symbol) {
        root = merklehash;
    }
    function mint(address acount,bytes32[] calldata proof,uint256 tokenid) external {
        require(mintedAddress[acount]==false);
        require(_verify(_leaf(acount), proof));
        _mint(acount, tokenid);
        mintedAddress[acount] = true;
    }
    function _leaf(address addr) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(addr));
    }
    //证明调用
    function _verify(bytes32 leaf, bytes32[] memory proof) internal view returns (bool) {
        return MerkleProof.verify(proof, leaf, root); 
    }
} 