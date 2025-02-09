// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {proDeposit} from "../src/pro.sol";

contract DeployScript is Script {
    function setUp() public {}

    function run() public {
        string memory pk = vm.envString("PRIVATE_KEY");
        bytes memory pkBytes = vm.parseBytes(pk);
        uint256 deployerPrivateKey = uint256(bytes32(pkBytes));

        vm.startBroadcast(deployerPrivateKey);
        proDeposit deposit = new proDeposit(address(0xaA8E23Fb1079EA71e0a56F48a2aA51851D8433D0));
        console.log("proDeposit deployed at: ", address(deposit));


        vm.stopBroadcast();
    }
}