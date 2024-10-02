// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
//委托投票
//用户可以自己或委托给另一个用户去给一个提案投票
contract Ballot{
    //用户状态
    struct Voter{
        uint weight;//投票权重
        bool voted;//是否投票
        address delegate;//委托给了谁
        uint vote;//投票的提案的索引
        uint256 time1;//特定权重的时间限制
    }
    //提案的状态
    struct Proposual{
        bytes32 name;//提案的名称
        uint voteCount;//得票数
    }
    //合约部署地址
    address public chairperson;
    //用户地址对应的用户状态
    mapping (address => Voter) public voters;
    //所有要投票的提案数组
    Proposual[] public proposuals;
    //开始时间 结束时间
    uint256 public startTime;
    uint256 public endTime;
    uint256 public times = 10 minutes;
    constructor(bytes32[] memory proposualsName) {
        chairperson = msg.sender;
        voters[chairperson].weight = 1; 
        startTime = block.timestamp;
        endTime = startTime + times; 
        for(uint i = 0;i < proposualsName.length;i++) {
            proposuals[i].name = proposualsName[i];
            proposuals[i].voteCount = 0;
        }
    }
    //给一个账户授予投票权 只有部署合约的地址才能调用
    function giveRightToVote(address a) external {
        require(msg.sender == chairperson);
        require(!voters[a].voted);
        require(voters[a].weight == 0);
        voters[a].weight = 1;
    }
    function setVoterWeight(address a, uint weight) public returns(uint256 beginTime) {
        require(msg.sender == chairperson);
        require(!voters[a].voted);
        require(voters[a].weight == 0);
        voters[a].weight = weight;
        voters[a].time1 = 5 minutes;
        beginTime = block.timestamp;
    }
    //委托投票 传入被委托的人的地址 
    function delegate(address to) external {
        //调用此函数的人的具体状态
        Voter storage sender = voters[msg.sender];
        require(sender.weight >= 1);
        require(!sender.voted);
        require(to != msg.sender);
        //一直到没有被委托的人
        while(voters[to].delegate != address(0)){
            to = voters[to].delegate;
            require(to != msg.sender);
        }
        //被委托的人的具体状态
        Voter storage _delegate = voters[to];
        require(_delegate.weight >= 1);
        //记录委托人投过票
        sender.voted = true;
        sender.delegate = to;
        //如果被委托人投过票 加票数
        if (_delegate.voted) {
            if (block.timestamp <= setVoterWeight(msg.sender,sender.weight) + sender.time1) {
            proposuals[_delegate.vote].voteCount += sender.weight;
            }else {
            proposuals[_delegate.vote].voteCount += 1;
            }
        }else {
            _delegate.weight += sender.weight;
        }
    }
    //投票
    function vote(uint proposual) external {
        Voter storage sender = voters[msg.sender];
        require(sender.weight >= 1);
        require(!sender.voted);
        require(block.timestamp >= startTime && block.timestamp <= endTime);
        sender.voted = true;
        sender.vote = proposual;
        if (block.timestamp <= setVoterWeight(msg.sender,sender.weight) + sender.time1) {
            proposuals[proposual].voteCount += sender.weight;
        }else {
            proposuals[proposual].voteCount += 1;
        }
    }
    //找出选票最多的提案
    function winner() public view returns(uint p) {
        uint winCount = 0;
        for (uint i = 0;i < proposuals.length;i++) {
            if (proposuals[i].voteCount > winCount) {
                winCount = proposuals[i].voteCount;
                p = i;
            }
        }
    }
    //返回最多选票的提案的名字
    function winnerName() external view returns(bytes32 ans) {
        ans = proposuals[winner()].name;
    }
}    