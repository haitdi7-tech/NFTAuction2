// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8;

contract AggreagatorV3{
    uint8 public immutable decimals;//价格小数位数
    int256 public latestAnswer;

    //初始化小数位数，初始价格
    constructor(uint8 _decimals,int256 _initalPrice){
        decimals = _decimals;
        latestAnswer = _initalPrice;
    }

    //模拟Chainlink的latestRounData返回价格
    function latestRoundData() external view returns(
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answerInRound
    ){
        return (0,latestAnswer,block.timestamp,block.timestamp,0);
    }

    //可以手动修改价格
    function updateAnswer(int256 _newPrice) public {
        latestAnswer = _newPrice;
    }
}