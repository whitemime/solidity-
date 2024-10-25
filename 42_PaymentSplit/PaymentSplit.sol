// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
//分账合约
contract PaymentSplit{
    //增加受益人事件 受益人地址 受益人份额
    event PayeeAdded(address account,uint256 shares);
    //受益人提款事件 受益人地址 受益人得到的钱
    event PaymentReleased(address to,uint256 amount);
    //合约收款事件
    event PaymentReceived(address from, uint256 amount);
    uint256 public totalShares;//总份额
    uint256 public totalReleased;//总支付
    mapping (address => uint256) public shares;//每个受益人的份额
    mapping (address => uint256) public released;//支付给每个受益人的金额
    address[] public payees;//受益人地址数组
    //初始化受益人地址数组和份额映射
    constructor(address[] memory _payees,uint256[] memory _shares) payable {
        require(_payees.length == _shares.length);
        require(_payees.length > 0);
        for (uint256 i = 0; i<_payees.length;i++) {
            _addPayee(_payees[i], _shares[i]);
        }
    }
    receive() external payable virtual {
        emit PaymentReceived(msg.sender,msg.value);
    }
    //分账函数 任何人都可以调用 但是金额只会发送给受益人
    function release(address payable _account) public virtual {
        //必须是受益人
        require(shares[_account] > 0);
        //计算应得的金额
        uint256 payment =releasable(_account);
        require(payment > 0);
        released[_account] += payment;
        totalReleased += payment;
        (bool success,) = _account.call{value:payment}("");
        require(success);
        emit PaymentReleased(_account,payment);
    }
    function releasable(address _account) public view returns(uint256) {
        //计算合约总收入
        uint256 totalReceived = address(this).balance + totalReleased;
        return pendingPayment(_account,totalReceived,released[_account]);
    }
    function pendingPayment(address _account,uint256 _totalReceived,uint256 _alreadyReleased) public view returns (uint256){
        return (_totalReceived * shares[_account]) / totalShares - _alreadyReleased;
    }
    function _addPayee(address _account,uint256 _accountShares) private {
        require(_account != address(0));
        require(_accountShares > 0);
        require(shares[_account] == 0);//没添加过
        payees.push(_account);
        shares[_account] = _accountShares;
        totalShares += _accountShares;
        emit PayeeAdded(_account, _accountShares);
    }
}