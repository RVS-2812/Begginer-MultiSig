// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {MultiSig} from "../src/MultiSig.sol";
// import {console2} from "lib/foundry-devops/lib/forge-std/src/console2.sol";
abstract contract CodeConstants {
    uint256 public constant INITIAL_BALANCE = 100 ether;
}

contract MultiSigTest is Test, CodeConstants {
    MultiSig public multiSig;

    function setUp() public {
        multiSig = new MultiSig();
        vm.deal(payable(address(multiSig)), 10 ether);
    }

    function testInitialOwner() view public {
        address[] memory owners = multiSig.getOwners();
        assertEq(owners.length, 1);
        assertEq(owners[0], address(this));
    }

    function testNotOwner() public {
        vm.prank(address(0x123));
        vm.expectRevert(MultiSig.NotOwner.selector);
        multiSig.proposeTransaction(address(0x456), 1 ether);
    }

    function testProposeOwnerSingleOwner() public {
        address newOwner = address(0x456);
        multiSig.proposeOwner(newOwner);
        address[] memory owners = multiSig.getOwners();
        assertEq(owners.length, 2);
        assertEq(owners[1], newOwner);
    }

    function testProposeOwnerMultipleOwnersSuccess() public {
        address newOwner = address(0x456);
        multiSig.proposeOwner(newOwner);
        address[] memory owners = multiSig.getOwners();
        assertEq(owners.length, 2);
        assertEq(owners[1], newOwner);

        // Propose another owner
        address anotherNewOwner = address(0x789);
        multiSig.proposeOwner(anotherNewOwner);
        owners = multiSig.getOwners();
        assertEq(owners.length, 2); // Should still be 2 since the second proposal is not yet approved

        // console.log("sus", owners[1]);
        vm.prank(newOwner);
        multiSig.SignProposedOwner(anotherNewOwner);
        owners = multiSig.getOwners();
        assertEq(owners.length, 3); // Now it should be 3 since the second proposal is approved
        assertEq(owners[2], anotherNewOwner);
    }
    
    function testProposeOwnerMultipleOwnersFailNotOwner() public {
        address newOwner = address(0x456);
        multiSig.proposeOwner(newOwner);
        address[] memory owners = multiSig.getOwners();

        // Propose another owner
        address anotherNewOwner = address(0x789);
        multiSig.proposeOwner(anotherNewOwner);
        owners = multiSig.getOwners();
        
        vm.expectRevert(MultiSig.NotOwner.selector);
        vm.prank(address(0x123));
        multiSig.SignProposedOwner(anotherNewOwner);
    }

    function testProposeOwnerMultipleOwnersFailAlreadySigned() public {
        address newOwner = address(0x456);
        multiSig.proposeOwner(newOwner);
        address[] memory owners = multiSig.getOwners();

        address anotherNewOwner = address(0x789);
        multiSig.proposeOwner(anotherNewOwner);
        owners = multiSig.getOwners();

        vm.expectRevert(MultiSig.AlreadySignedOwnerRequest.selector);
        multiSig.SignProposedOwner(anotherNewOwner);
    }

    function testProposeOwnerMultipleOwnersReject() public {
        address newOwner = address(0x456);
        multiSig.proposeOwner(newOwner);
        address[] memory owners = multiSig.getOwners();

        // Propose another owner
        address anotherNewOwner = address(0x789);
        multiSig.proposeOwner(anotherNewOwner);
        owners = multiSig.getOwners();
        assertEq(owners.length, 2); // Should still be 2 since the second proposal is not yet approved

        vm.prank(newOwner);
        multiSig.RejectProposedOwner(anotherNewOwner);
        owners = multiSig.getOwners();
        assertEq(owners.length, 2); // Now it should be 2 since the second proposal is rejected

    }

    function testProposeTransaction() public {


        address recipient = address(0x456);
        uint256 amount = 1 ether;
        multiSig.proposeTransaction(recipient, amount);
        MultiSig.Proposal[] memory proposals = multiSig.getProposaedTransactions();
        assertEq(proposals.length, 0); // since only 1 owner, the transaction should be executed immediately and not stored as a proposal
    }

    function testProposeTransactionMultipleOwners() public {
        address newOwner = address(0x456);
        multiSig.proposeOwner(newOwner);
        address[] memory owners = multiSig.getOwners();
        assertEq(owners.length, 2);
        assertEq(owners[1], newOwner);

        address recipient = address(0x789);
        uint256 amount = 1 ether;
        multiSig.proposeTransaction(recipient, amount);
        MultiSig.Proposal[] memory proposals = multiSig.getProposaedTransactions();
        assertEq(proposals.length, 1); // since there are multiple owners, the transaction should be stored as a proposal
        assertEq(proposals[proposals.length - 1].to, recipient);
        assertEq(proposals[proposals.length - 1].value, amount);

        vm.prank(newOwner);
        multiSig.SignProposedTransaction(0);
        proposals = multiSig.getProposaedTransactions();
        assertEq(proposals.length, 0); // since the transaction has been executed, the

    }

        function testProposeTransactionMultipleOwnersInsufficientFunds() public {
        address newOwner = address(0x456);
        multiSig.proposeOwner(newOwner);
        address[] memory owners = multiSig.getOwners();
        assertEq(owners.length, 2);
        assertEq(owners[1], newOwner);

        address recipient = address(0x789);
        uint256 amount = 11 ether;
        multiSig.proposeTransaction(recipient, amount);
        MultiSig.Proposal[] memory proposals = multiSig.getProposaedTransactions();
        assertEq(proposals.length, 1); // since there are multiple owners, the transaction should be stored as a proposal
        assertEq(proposals[proposals.length - 1].to, recipient);
        assertEq(proposals[proposals.length - 1].value, amount);

        vm.prank(newOwner);
        vm.expectRevert(MultiSig.insufficientFunds.selector);

        multiSig.SignProposedTransaction(0);
        proposals = multiSig.getProposaedTransactions();
        // assertEq(proposals.length, 0); // since the transaction has been executed, the

    }





}
