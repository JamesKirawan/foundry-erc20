// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {DeployOurToken} from "script/DeployOurToken.s.sol";
import {OurToken} from "src/OurToken.sol";

interface MintableToken {
    function mint(address, uint256) external;
}

contract OurTokenTest is Test {
    OurToken public ourToken;
    DeployOurToken public deployer;

    address bob = makeAddr("bob");
    address alice = makeAddr("alice");
    address charlie = makeAddr("charlie");

    uint256 public constant STARTING_BALANCE = 100 ether;

    function setUp() public {
        deployer = new DeployOurToken();
        ourToken = deployer.run();

        vm.prank(msg.sender);
        ourToken.transfer(bob, STARTING_BALANCE);
    }

    function testBobBalance() public view {
        assertEq(STARTING_BALANCE, ourToken.balanceOf(bob));
    }

    function testAllowancesWorks() public {
        uint256 initialAllowance = 1000;

        // Bob approves Alice to spend tokens on her behalf
        vm.prank(bob);
        ourToken.approve(alice, initialAllowance);

        uint256 transferAmount = 500;

        vm.prank(alice);
        ourToken.transferFrom(bob, alice, transferAmount);

        assertEq(ourToken.balanceOf(alice), transferAmount);
        assertEq(ourToken.balanceOf(bob), STARTING_BALANCE - transferAmount);
    }

    // Test for transferring tokens
    function testTransfer() public {
        uint256 transferAmount = 50;
        vm.prank(msg.sender);
        ourToken.transfer(charlie, transferAmount);

        assertEq(ourToken.balanceOf(charlie), transferAmount);
        assertEq(
            ourToken.balanceOf(msg.sender),
            deployer.INITIAL_SUPPLY() - STARTING_BALANCE - transferAmount
        );
    }

    // Test for failed transfer due to insufficient balance
    function testTransferInsufficientBalance() public {
        uint256 transferAmount = 1000 ether; // Exceed the initial supply
        vm.prank(msg.sender);

        vm.expectRevert();
        ourToken.transfer(bob, transferAmount);
    }

    function testInitialSupply() public view {
        assertEq(ourToken.totalSupply(), deployer.INITIAL_SUPPLY());
    }

    function testUsersCantMint() public {
        vm.expectRevert();
        MintableToken(address(ourToken)).mint(address(msg.sender), 1);
    }

    // Test for checking allowance
    function testAllowance() public {
        uint256 allowanceAmount = 200;
        vm.prank(msg.sender);
        ourToken.transfer(charlie, allowanceAmount);

        vm.prank(charlie);
        ourToken.approve(alice, allowanceAmount);

        assertEq(ourToken.allowance(charlie, alice), allowanceAmount);
    }

    // Test for failed transferFrom due to insufficient allowance
    function testTransferFromInsufficientAllowance() public {
        uint256 transferAmount = 100;
        vm.prank(msg.sender);
        ourToken.transfer(charlie, transferAmount);

        // Charlie approves Alice for 50 tokens
        vm.prank(charlie);
        ourToken.approve(alice, 50);

        // Alice attempts to transfer 100 tokens (greater than her allowance)
        vm.prank(alice);
        vm.expectRevert();
        ourToken.transferFrom(charlie, alice, 100);
    }

    // Test for resetting allowance
    function testResetAllowance() public {
        uint256 allowanceAmount = 100;
        vm.prank(msg.sender);
        ourToken.transfer(charlie, allowanceAmount);

        // Charlie approves Alice for 100 tokens
        vm.prank(charlie);
        ourToken.approve(alice, allowanceAmount);

        // Charlie resets allowance to 0
        vm.prank(charlie);
        ourToken.approve(alice, 0);

        assertEq(ourToken.allowance(charlie, alice), 0);
    }

    // Test for transferring more than available allowance
    function testTransferExceedsAllowance() public {
        uint256 initialAllowance = 100;

        vm.prank(msg.sender);
        ourToken.transfer(charlie, initialAllowance);

        // Charlie approves Alice for 100 tokens
        vm.prank(charlie);
        ourToken.approve(alice, initialAllowance);

        // Alice transfers 100 tokens
        vm.prank(alice);
        ourToken.transferFrom(charlie, alice, 100);

        // Alice attempts to transfer another 50 tokens (which is beyond the allowance)
        vm.prank(alice);
        vm.expectRevert();
        ourToken.transferFrom(charlie, alice, 50);
    }
}
