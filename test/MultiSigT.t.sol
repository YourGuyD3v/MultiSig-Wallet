// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {MultiSigWallet} from "src/MultiSigWallet.sol";

contract MultiSigTest is Test {
    MultiSigWallet multisig;

    address public owner1 = makeAddr("owner1");
    address public owner2 = makeAddr("owner2");
    address public owner3 = makeAddr("owner3");
    address public nonOwner = makeAddr("nonOwner");
    address public to = makeAddr("to");
    uint256 public numConfirmationsRequired = 2;

    function setUp() public {
        address[] memory owners = new address[](3);
        owners[0] = owner1;
        owners[1] = owner2;
        owners[2] = owner3;

        vm.prank(owner1);
        multisig = new MultiSigWallet(owners, numConfirmationsRequired);
    }

    function test_submitTransaction() public {
        vm.startPrank(owner1);
        multisig.submiteTransaction(to, 1e18, "");
        (address toAddress, uint256 value, , , ) = multisig.getTransactionIndex(0);
        assertEq(toAddress, to, "Incorrect transaction 'to' address");
        assertEq(value, 1e18, "Incorrect transaction value");
        vm.stopPrank();
    }

    function test_confirmTransaction() public {
        vm.startPrank(owner1);
        multisig.submiteTransaction(to, 1e18, "");
        vm.stopPrank();

        vm.startPrank(owner2);
        multisig.confirmTransaction(0);
        (, , , , uint256 numConfirmations) = multisig.getTransactionIndex(0);
        assertEq(numConfirmations, 1, "Incorrect confirmation count");
        vm.stopPrank();
    }

    function test_revokeConfirmation() public {
        vm.startPrank(owner1);
        multisig.submiteTransaction(to, 1e18, "");
        multisig.confirmTransaction(0);
        multisig.revokeConfirmation(0);
        (, , , , uint256 numConfirmations) = multisig.getTransactionIndex(0);
        assertEq(numConfirmations, 0, "Confirmation was not revoked");
        vm.stopPrank();
    }

    function test_executeTransaction() public {
        vm.startPrank(owner1);
        vm.deal(address(multisig), 1e18);
        multisig.submiteTransaction(to, 1e18, "");
        multisig.confirmTransaction(0);
        vm.stopPrank();

        vm.startPrank(owner2);
        multisig.confirmTransaction(0);

        vm.startPrank(owner3);
        multisig.confirmTransaction(0);

        console2.log("multi-sig balance before: ", address(multisig).balance);
        console2.log("to balance before: ", address(to).balance);

        multisig.executeTransaction(0);
        (, , , bool executed, ) = multisig.getTransactionIndex(0);

        console2.log("multi-sig balance after: ", address(multisig).balance);
        console2.log("to balance after: ", address(to).balance);
        assertTrue(executed, "Transaction was not executed");
        vm.stopPrank();
    }

    function test_failSubmitTransactionByNonOwner() public {
        vm.expectRevert("Multisig: not true owner");
        vm.prank(nonOwner);
        multisig.submiteTransaction(to, 1e18, "");
    }

    function test_failExecuteTransactionWithoutEnoughConfirmations() public {
        vm.startPrank(owner1);
        multisig.submiteTransaction(to, 1e18, "");
        vm.stopPrank();

        vm.startPrank(owner2);
        vm.expectRevert("Multisig: cannot execute tx");
        multisig.executeTransaction(0);
        vm.stopPrank();
    }

    function test_changeOwner() public {
        vm.startPrank(owner1);
        multisig.submiteOwnershipCompromised(owner3, nonOwner);
        vm.stopPrank();

        vm.startPrank(owner2);
        multisig.confrimOwnerCompromised(0);

        vm.startPrank(owner3);
        multisig.confrimOwnerCompromised(0);

        multisig.executeChangeOwner(0);
        assertTrue(multisig.isOwner(nonOwner), "New owner not added");
        assertFalse(multisig.isOwner(owner3), "Old owner not removed");
        vm.stopPrank();
    }

    function test_failExecuteChangeOwnerWithoutEnoughConfirmations() public {
        vm.startPrank(owner1);
        multisig.submiteOwnershipCompromised(owner3, nonOwner);
        vm.expectRevert("Multisig: cannot execute tx");
        multisig.executeChangeOwner(0);
        vm.stopPrank();
    }

    function test_getTransactionIndex() public {
        test_executeTransaction();

        (
            address _to,
            uint256 value,
            bytes memory data,
            bool executed,
            uint256 numConfirmations
        ) = multisig.getTransactionIndex(0);

        console2.log("tx index to: ", _to);
        console2.log("tx index value: ", value);
        console2.log("tx index data: ", string(data));
        console2.log("tx index executed: ", executed);
        console2.log("tx index numConfirmations: ", numConfirmations);
    }

    function test_getOwnershipChangeProposal() public {
        test_changeOwner();

       (
        address reportingOwner, 
        address compromisedOwner, 
        address newOwnerSuggested,
        bool executed,
        uint256 numConfirmations
       ) = multisig.getOwnershipChangeProposal(0);

        console2.log("tx index reportingOwner: ", reportingOwner);
        console2.log("tx index compromisedOwner: ", compromisedOwner);
        console2.log("tx index newOwnerSuggested: ", newOwnerSuggested);
        console2.log("tx index execute: ", executed);
        console2.log("tx index numConfirmations: ", numConfirmations);
    }

    function test_isOwnershipChangeProposalConfirmed() public {
        assertFalse(multisig.isOwnershipChangeProposalConfirmed(0, owner3));

        test_changeOwner();

        assertTrue(multisig.isOwnershipChangeProposalConfirmed(0, owner3));
    }

    function test_getOwnershipChangeProposalCount() public {
        uint256 countBefore = multisig.getOwnershipChangeProposalCount();
        assertEq(countBefore, 0);

        vm.startPrank(owner1);
        multisig.submiteOwnershipCompromised(owner3, nonOwner);
        vm.stopPrank();

        uint256 countAfter = multisig.getOwnershipChangeProposalCount();
        assertEq(countAfter, 1);
    }

    function test_getTransactionCount() public {
        uint256 countBefore = multisig.getTransactionCount();
        assertEq(countBefore, 0);

        vm.startPrank(owner1);
        multisig.submiteTransaction(to, 1e18, "");
        multisig.confirmTransaction(0);
        vm.stopPrank();

        uint256 countAfter = multisig.getTransactionCount();
        assertEq(countAfter, 1);
    }

    function test_getOwners() public {
        address[] memory owners = multisig.getOwners();
        assertEq(owners[2], owner3);
    }
}
