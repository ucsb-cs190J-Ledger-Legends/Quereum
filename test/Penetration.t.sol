// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "lib/forge-std/src/Test.sol";
import "lib/forge-std/src/Vm.sol";
import {Quereum} from "src/Quereum.sol";

contract PenetrationTest is Test {
    Quereum public quereum;

    // ===================== //
    // ==== local roles ==== //
    // ===================== //

    address public alice = address(0x01);
    address public bob = address(0x02);
    address public eve = address(0x03);
    address public mallory = address(0x04);

    function setUp() public {
        deal(alice, 100 ether);
        deal(bob, 100 ether);
        deal(eve, 100 ether);
        deal(mallory, 100 ether);
        
        quereum = new Quereum();
    }

    // ========================== //
    // ==== local test cases ==== //
    // ========================== //

    // Test if alice can post a question without registering.
    // The app should revert the transaction.
    // If a user could interact with our app without registering,
    // we would not be able to track malicious actions (such as
    // endorsing a question multiple times).
    function test_no_registration() public {
        vm.startPrank(alice);
        vm.expectRevert("User not registered");
        quereum.postQuestion(
            "Can I post a question without registering?",
            block.timestamp + 1000,
            0 ether
        );
        vm.stopPrank();
    }
}