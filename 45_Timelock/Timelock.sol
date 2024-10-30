// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
//时间锁合约 他可以将智能合约的某些功能锁定一段时间
contract Timelock{
    //交易取消事件 交易哈希 目标合约地址 发送的数量 函数签名 交易执行的区块链时间戳
    event CancelTransaction(bytes32 indexed txHash,address indexed target,uint value,string signature,bytes data,uint executeTime);
    //交易执行事件
    event ExecuteTransaction(bytes32 indexed txHash,address indexed target,uint value,string signature,bytes data,uint executeTime);
    //交易创建并进入队列事件
    event QueueTransaction(bytes32 indexed txHash,address indexed target,uint value,string signature,bytes data,uint executeTime);
    //修改管理员地址事件
    event NewAdmin(address indexed newAdmin);

    address public admin;//管理员地址
    uint public constant GRACE_PERIOD = 7 days;//交易有效期 过期的交易作废
    uint public delay;//交易锁定时间
    mapping (bytes32 => bool) public queueTransactions; //记录时间锁队列中的交易

    modifier onlyOwner() {
        require(msg.sender == admin);
        _;
    }
    //被修饰的函数只能被时间锁合约执行
    modifier onlyTimelock() {
        require(msg.sender == address(this));
        _;
    }
    constructor (uint _delay) {
        delay = _delay;
        admin = msg.sender;
    }
    //修改管理员地址
    function changeAdmin(address newAdmin) public onlyTimelock {
        admin = newAdmin;
        emit NewAdmin(newAdmin);
    }
    //创建交易并且添加到时间锁队列中
    function queueTransaction(address target,uint256 value,string memory signature,bytes memory data,uint256 executeTime) public onlyOwner returns(bytes32) {
        //交易执行的时间要大于阿巴阿巴
        require(executeTime >= getBlockTimestamp() + delay);
        //计算哈希
        bytes32 txHash = getTxHash(target, value, signature, data, executeTime);
        // 将交易添加到队列
        queueTransactions[txHash] = true;
        emit QueueTransaction(txHash, target, value, signature, data, executeTime);
        return txHash;
    }
    //取消特定交易
    function cancelTransaction(address target, uint256 value, string memory signature, bytes memory data, uint256 executeTime) public onlyOwner{
        bytes32 txHash = getTxHash(target, value, signature, data, executeTime);
        require(queueTransactions[txHash]);
        queueTransactions[txHash] = false;
        emit CancelTransaction(txHash, target, value, signature, data, executeTime);
    }
    //执行特定交易
    function executeTransaction(address target, uint256 value, string memory signature, bytes memory data, uint256 executeTime) public payable onlyOwner returns (bytes memory) {
        bytes32 txHash = getTxHash(target, value, signature, data, executeTime);
        require(queueTransactions[txHash]);
        //达到交易的执行时间
        require(getBlockTimestamp() >= executeTime);
        //交易未过期
        require(getBlockTimestamp() <= executeTime + GRACE_PERIOD);
        queueTransactions[txHash] = false;
          // 获取call data
        bytes memory callData;
        if (bytes(signature).length == 0) {
            callData = data;
        } else {
        // 这里如果采用encodeWithSignature的编码方式来实现调用管理员的函数，请将参数data的类型改为address。
        //不然会导致管理员的值变为类似"0x0000000000000000000000000000000000000020"的值。其中的0x20是代表字节数组长度的意思.
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }
        // 利用call执行交易
        (bool success, bytes memory returnData) = target.call{value: value}(callData);
        require(success, "Timelock::executeTransaction: Transaction execution reverted.");

        emit ExecuteTransaction(txHash, target, value, signature, data, executeTime);

        return returnData;
    }
    //获取当前时间戳
    function getBlockTimestamp() public view returns(uint) {
        return block.timestamp;
    }
    //计算交易哈希
    function getTxHash(
        address target,
        uint value,
        string memory signature,
        bytes memory data,
        uint executeTime
    )public pure returns(bytes32) {
        return keccak256(abi.encode(target, value, signature, data, executeTime));
    }
}