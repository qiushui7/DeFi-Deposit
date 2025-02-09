// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract baseDeposit {
    address public owner;
    mapping (address => uint256) public addressToBalance;
    address[] public addressList;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    function deposit() public payable virtual {
        require(msg.value > 0, "must deposit more than 0");
        addressToBalance[msg.sender] += msg.value;
        addressList.push(msg.sender);
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) public virtual {
        require(addressToBalance[msg.sender] >= amount, "not enough balance");
        addressToBalance[msg.sender] -= amount;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) {
            revert("transfer failed");
        }
        emit Withdraw(msg.sender, amount);
    }

    function ownerWithdraw() public {
        require(msg.sender == owner, "Only owner can use ownerWithdraw");
        uint256 totalBalance = 0;
        for (uint256 i = 0; i < addressList.length; i++) {
            totalBalance += addressToBalance[addressList[i]];
            addressToBalance[addressList[i]] = 0;
        }
        addressList = new address[](0);
        (bool success, ) = payable(owner).call{value: totalBalance}("");
        if (!success) {
            revert("transfer failed");
        }
        emit Withdraw(owner, totalBalance);
    }
}
