// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

//多签钱包 一次交易需要多人签名

 contract MultisigWallet{
    event ExecutionSuccess(bytes32 txHash);//交易成功事件
    event ExecutionFailure(bytes32 txHash);//交易失败事件
    address[] public owners;//多签持有人数组
    mapping (address => bool) public isOwner; //记录地址是否为多签中的人
    uint256 public ownerCount;//多签持有人数量
    uint256 public threshold;//交易至少这么多人签名后才执行
    uint256 public nonce;//交易成功后加一 防止双花攻击
    receive() external payable {}
    //构造函数
    constructor(address[] memory _owners,uint256 _threshold) {
        _setupOwners(_owners, _threshold);
    } 
    //初始化函数
    function _setupOwners(address[] memory _owners,uint256 _threshold) internal {
        require(threshold == 0);//确保没初始化
        require(_threshold <= _owners.length);
        require(_threshold >= 1);
        for (uint256 i = 0;i < _owners.length; i++) {
            require(_owners[i] != address(0) && _owners[i] != address(this) && !isOwner[_owners[i]]);
            owners.push(_owners[i]);
            isOwner[_owners[i]] = true;
        }
        ownerCount = _owners.length;
        threshold = _threshold;
    }
    function execTransaction(address to,uint256 value,bytes memory data,bytes memory signatures) public payable virtual returns(bool success) {
        bytes32 txHash = encodeTransactionData(to, value, data, nonce, block.chainid);
        nonce++;
        checkSignatures(txHash, signatures);
        (success,) = to.call{value:value}(data);
        if (success) emit ExecutionSuccess(txHash);
        else emit ExecutionFailure(txHash); 
    }
    //检验签名 消息哈希 整体签名
    function checkSignatures(bytes32 dataHash,bytes memory signatures) public view {
        uint256 _threshold = threshold;
        require(_threshold > 0);
        require(signatures.length >= _threshold);
        address lastOwner = address(0); //最后一个签名人的地址
        address currentOwner; //记录每一个解析出来的地址
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 i;
        for(i = 0;i < _threshold; i++) {
            (v,r,s) = signatureSplit(signatures, i);
            //ecrecover函数用于恢复签名者的地址
            currentOwner = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash)), v, r, s);
            require(currentOwner > lastOwner);
            lastOwner = currentOwner;
        }
    }
    //分离出签名的数据格式 输入签名 签名的位置（这里签名按从小到大排序） 
    function signatureSplit(bytes memory signatures,uint256 pos) internal pure returns(uint8 v,bytes32 r,bytes32 s) {
        assembly{
            let signaturePos := mul(0x41,pos)
            r := mload(add(signatures, add(signaturePos, 0x20)))
            s := mload(add(signatures, add(signaturePos, 0x40)))
            v := and(mload(add(signatures, add(signaturePos, 0x41))), 0xff)
        }
    }
    //编码交易数据 目标合约地址 发送的数量 calldata 交易的nonce 链的id
    function encodeTransactionData(
        address to,
        uint256 value,
        bytes memory data,
        uint256 _nonce,
        uint256 chainid
    ) public pure returns(bytes32) {
        bytes32 safeTxHash = keccak256(abi.encode(to,value,keccak256(data),_nonce,chainid));
        return safeTxHash;
    }
 }