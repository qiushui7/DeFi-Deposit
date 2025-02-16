// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {proDeposit} from "../src/pro.sol";

contract proDepositTest is Test {
    proDeposit public deposit;
    address public user1;
    address public user2;
    address public owner;

    function setUp() public {
        // 部署合约
        deposit = new proDeposit();
        owner = address(this);
        
        // 创建测试用户
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        
        // 给测试用户一些 ETH
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
        
        // 确保合约有足够的 ETH 支付利息
        vm.deal(address(deposit), 100 ether);
    }

    // 测试基本存款功能
    function testDeposit() public {
        vm.prank(user1);
        deposit.deposit{value: 1 ether}();
        
        (uint256 amount, uint256 depositTime, uint256 lastInterestUpdate) = deposit.userDeposits(user1);
        assertEq(amount, 1 ether, "Deposit amount should be 1 ether");
        assertEq(depositTime, block.timestamp, "Deposit time should be current timestamp");
        assertEq(lastInterestUpdate, block.timestamp, "Last interest update should be current timestamp");
    }

    // 测试零存款
    function testZeroDeposit() public {
        vm.prank(user1);
        vm.expectRevert("Deposit amount must be greater than 0");
        deposit.deposit{value: 0}();
    }

    // 测试利息计算
    function testInterestCalculation() public {
        // 用户存款 1 ETH
        vm.prank(user1);
        deposit.deposit{value: 1 ether}();
        
        // 模拟时间经过 1 年
        skip(365 days);
        
        // 计算利息 (5% 年化利率)
        uint256 interest = deposit.calculateInterest(user1);
        assertApproxEqAbs(interest, 0.05 ether, 0.001 ether, "Interest should be approximately 5% after one year");
    }

    // 测试部分提款
    function testPartialWithdraw() public {
        
        // 存款 2 ETH
        vm.startPrank(user1);
        deposit.deposit{value: 2 ether}();
        
        // 等待一段时间
        skip(180 days);
        
        // 提取 1 ETH
        deposit.withdraw(1 ether);
        vm.stopPrank();
        
        (uint256 amount,,) = deposit.userDeposits(user1);
        // 余额应该大于 1 ETH (包含约2.5%的利息)
        assertTrue(amount > 1 ether, "Remaining balance should be more than 1 ether due to interest");
    }

    // 测试全额提款
    function testFullWithdraw() public {
        
        // 存款 1 ETH
        vm.startPrank(user1);
        deposit.deposit{value: 1 ether}();
        
        // 等待一年
        skip(365 days);
        
        // 计算总金额（本金+利息）
        uint256 totalBalance = deposit.calculateInterest(user1) + 1 ether;
        
        // 全额提款
        deposit.withdraw(totalBalance);
        vm.stopPrank();
        
        (uint256 amount, uint256 depositTime, uint256 lastInterestUpdate) = deposit.userDeposits(user1);
        assertEq(amount, 0, "Balance should be 0 after full withdrawal");
        assertEq(depositTime, 0, "Deposit time should be reset");
        assertEq(lastInterestUpdate, 0, "Last interest update should be reset");
    }

    // 测试多次存款的利息计算
    function testMultipleDeposits() public {
        
        vm.startPrank(user1);
        
        // 第一次存款
        deposit.deposit{value: 1 ether}();
        
        // 等待半年
        skip(180 days);
        
        // 第二次存款
        deposit.deposit{value: 1 ether}();
        
        // 再等待半年
        skip(180 days);
        
        uint256 interest = deposit.calculateInterest(user1);
        assertTrue(interest > 0, "Should have accumulated interest");
        
        vm.stopPrank();
    }

    // 测试 owner 存款功能
    function testOwnerDeposit() public {
        deposit.ownerDeposit{value: 5 ether}();
        assertEq(address(deposit).balance, 105 ether, "Contract balance should be 5 ether");
    }

    // 测试非 owner 调用 ownerDeposit
    function test_RevertWhen_NonOwnerDeposit() public {
        vm.prank(user1);
        vm.expectRevert("Only owner can call this function");
        deposit.ownerDeposit{value: 1 ether}();
    }

    // 测试提款金额超过余额
    function testOverWithdraw() public {
        
        vm.startPrank(user1);
        deposit.deposit{value: 1 ether}();
        
        vm.expectRevert("Insufficient balance");
        deposit.withdraw(2 ether);
        vm.stopPrank();
    }

    receive() external payable {}
} 