// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

contract Crowd_funding{
    address public manager;
    mapping(address=>uint) public contributors;

    uint target;
    uint deadline;
    uint minContri;
    uint raisedCapital;
    uint totalContributors;

    // for managing multiple requests
    struct req{
        string desc;
        address recipient;
        uint value;
        bool isCompleted;
        uint totalVoters;
        mapping(address=>bool) voters;     
    }
    mapping(uint=>req) reqList;
    uint reqID;


    constructor(uint _target, uint _deadline, uint _minContri){
        target = _target;
        deadline = block.timestamp + _deadline;
        minContri = _minContri;
        manager = msg.sender; 
    }

    function sendEth() public payable
    {
        require(msg.value>=minContri, "not enough contri");
        require(block.timestamp < deadline, "dealine has gone");

        if(contributors[msg.sender]==0){
            totalContributors++;
        }
        contributors[msg.sender]+=msg.value;
        raisedCapital+=msg.value;
    } 

    function getBalance() public view returns(uint)
    {
        return address(this).balance;
    }

    function refund() public payable
    {
        require(contributors[msg.sender]>0);
        require(block.timestamp>deadline && raisedCapital< target);

        address payable user = payable(msg.sender);
        user.transfer(contributors[msg.sender]);
        contributors[msg.sender]=0;
    }

    modifier OnlyManager(){
        require(msg.sender==manager, "only accessible to manager");
        _;
    }

    function crateReq(string memory _desc, address _recipient, uint _value) public OnlyManager{
        req storage newReq = reqList[reqID];
        newReq.desc = _desc;
        newReq.recipient = _recipient;
        newReq.value = _value;
        newReq.isCompleted=false;
        newReq.totalVoters=0;

        reqID++;
    }

    function vote(uint _reqID) public
    {
        require(contributors[msg.sender]>0);
        req storage thisReq = reqList[_reqID];
        require(thisReq.voters[msg.sender]==false); //to ensure user didn't voted yet

        thisReq.voters[msg.sender]=true;
        thisReq.totalVoters++;
    }

    function transaction(uint _reqID) public payable OnlyManager
    {   require(raisedCapital>=target);
        req storage thisReq= reqList[_reqID];
        require(thisReq.totalVoters> totalContributors/2, "you have already voted");  

        address payable user = payable(thisReq.recipient);
        user.transfer(thisReq.value);
        thisReq.isCompleted=true;
    }
}
