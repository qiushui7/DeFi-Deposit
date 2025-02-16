// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {baseDeposit} from "./base.sol";

contract proDeposit is baseDeposit {
    uint256 public constant ANNUAL_RATE = 500;
    uint256 public constant PRECISION = 1e18;
    
    struct DepositRecord {
        uint256 amount;
        uint256 depositTime;
        uint256 lastInterestUpdate;
    }
    
    mapping(address => DepositRecord) public userDeposits;

    constructor() baseDeposit() {}

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function deposit() public payable override {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        
        // 先结算之前的利息
        if (userDeposits[msg.sender].amount > 0) {
            uint256 interest = calculateInterest(msg.sender);
            userDeposits[msg.sender].amount += interest;
            userDeposits[msg.sender].lastInterestUpdate = block.timestamp;
        } else {
            // 新用户首次存款
            userDeposits[msg.sender].depositTime = block.timestamp;
            userDeposits[msg.sender].lastInterestUpdate = block.timestamp;
        }
        
        userDeposits[msg.sender].amount += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function calculateInterest(address user) public view returns (uint256) {
        DepositRecord memory record = userDeposits[user];
        if (record.amount == 0) return 0;

        uint256 timeElapsed = block.timestamp - record.lastInterestUpdate;
        
        // 使用更高精度的计算方式
        uint256 interest = (record.amount * ANNUAL_RATE * timeElapsed * PRECISION) 
            / (10000 * 31536000);
        return interest / PRECISION;
    }

    function withdraw(uint256 needAmount) public override {
        DepositRecord storage record = userDeposits[msg.sender];
        require(record.amount > 0, "No deposit found");

        uint256 interest = calculateInterest(msg.sender);
        uint256 totalAmount = record.amount + interest;
        require(totalAmount >= needAmount, "Insufficient balance");
        
        // 更新余额和最后更新时间
        record.amount = totalAmount - needAmount;
        record.lastInterestUpdate = block.timestamp;
        
        // 如果全部提取，重置存款时间
        if (record.amount == 0) {
            record.depositTime = 0;
            record.lastInterestUpdate = 0;
        }

        (bool success, ) = payable(msg.sender).call{value: needAmount}("");
        require(success, "Transfer failed");
        emit Withdraw(msg.sender, needAmount);
    }

    function ownerDeposit() public payable onlyOwner {
      require(msg.value > 0, "Deposit amount must be greater than 0");
      emit Deposit(msg.sender, msg.value);
    }

}
