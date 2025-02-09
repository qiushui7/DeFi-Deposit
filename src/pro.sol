// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {baseDeposit} from "./base.sol";
import {IERC20} from "./IERC20.sol";

contract proDeposit is baseDeposit {
    uint256 public constant ANNUAL_RATE = 500;
    IERC20 public immutable token;
    struct DepositInfo {
        uint256 amount;
        uint256 depositTime;
        bool isToken;
    }
    
    mapping(address => DepositInfo) public userDeposits;

    constructor(address _token) baseDeposit() {
        token = IERC20(_token);
    }

    function deposit() public payable override {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        
        if (userDeposits[msg.sender].amount > 0) {
            uint256 interest = calculateInterest(msg.sender);
            userDeposits[msg.sender].amount += interest;
        }
        
        userDeposits[msg.sender].amount += msg.value;
        userDeposits[msg.sender].depositTime = block.timestamp;
        emit Deposit(msg.sender, msg.value);
    }

    function depositToken(uint256 amount) public {
        require(amount > 0, "Deposit amount must be greater than 0");
        require(token.transferFrom(msg.sender, address(this), amount), "Token transfer failed");
        
        if (userDeposits[msg.sender].amount > 0) {
            uint256 interest = calculateInterest(msg.sender);
            userDeposits[msg.sender].amount += interest;
        }
        
        userDeposits[msg.sender].amount += amount;
        userDeposits[msg.sender].depositTime = block.timestamp;
        userDeposits[msg.sender].isToken = true;

        emit Deposit(msg.sender, amount);
    }

    function calculateInterest(address user) public view returns (uint256) {
        DepositInfo memory userDeposit = userDeposits[user];
        if (userDeposit.amount == 0) return 0;

        uint256 timeElapsed = block.timestamp - userDeposit.depositTime;
        
        uint256 interest = (userDeposit.amount * ANNUAL_RATE * timeElapsed) / (10000 * 31536000);
        
        return interest;
    }

    function withdraw(uint256 needAmount) public override {
      uint256 amount = userDeposits[msg.sender].amount;
      require(amount > 0, "No deposit found");

      uint256 interest = calculateInterest(msg.sender);
      uint256 totalAmount = amount + interest;

      bool isToken = userDeposits[msg.sender].isToken;
      if (isToken) {
        require(totalAmount >= needAmount, "Insufficient contract balance");

        userDeposits[msg.sender].amount = totalAmount - needAmount;
        require(token.transfer(msg.sender, needAmount), "Token transfer failed");
      }else{
        require(totalAmount >= needAmount, "Insufficient contract balance");

        userDeposits[msg.sender].amount = totalAmount - needAmount;
        (bool success, ) = payable(msg.sender).call{value: needAmount}("");
        require(success, "Transfer failed");
      }
      emit Withdraw(msg.sender, needAmount);
    }
}
