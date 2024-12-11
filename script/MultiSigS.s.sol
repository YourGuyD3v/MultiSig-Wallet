// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {MultiSigWallet} from "src/MultiSigWallet.sol";

contract MultiSigS is Script {

    MultiSigWallet multisig;

    address public owner1 = makeAddr("owner1");
    address public owner2 = makeAddr("owner2");
    address public owner3 = makeAddr("owner3");
    uint256 public numConfirmationsRequired = 2;

    function setUp() public {}

    function run() public returns (MultiSigWallet){
        address[] memory owners = new address[](3);
        owners[0] = owner1;
        owners[1] = owner2;
        owners[2] = owner3;

        vm.startBroadcast();

        multisig = new MultiSigWallet(owners, numConfirmationsRequired);

        vm.stopBroadcast();

        return multisig;
    }
}
