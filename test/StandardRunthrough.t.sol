// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "lib/forge-std/src/Test.sol";
import "lib/forge-std/src/Vm.sol";
import {Quereum} from "src/Quereum.sol";

contract StandardRunthroughTest is Test {
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

    // Test that users can register.
    // Users should be able to register, and the app should
    // keep track of the username.
    function test_register() public {
        vm.startPrank(alice);
        quereum.register("alice");
        (string memory account_name,) = quereum.viewUserDetails();
        assertEq(account_name, "alice");
        vm.stopPrank();

        vm.startPrank(bob);
        quereum.register("bob");
        vm.stopPrank();

        vm.startPrank(eve);
        quereum.register("eve");
        vm.stopPrank();

        vm.startPrank(mallory);
        quereum.register("mallory");
        vm.stopPrank();
    }

    // Test that users can send money to the contract.
    // The app should be able to track the balance of the user.
    function test_add_balance() public {
        test_register(); // Continue from last time.

        vm.startPrank(alice);
        quereum.addBalance{value: 50 ether}();
        (, uint256 account_balance) = quereum.viewUserDetails();
        assertEq(account_balance, 50 ether);
        vm.stopPrank();

        vm.startPrank(bob);
        quereum.addBalance{value: 10 ether}();
        vm.stopPrank();
    }

    // Test that users can add a question.
    // The app should be able to record the question.
    function test_local_host_balance() public {
        test_add_balance(); // Continue from last time.

        vm.startPrank(alice);
        quereum.postQuestion(
            "What is the best CS course at UCSB?",
            block.timestamp + 1000,
            20 ether
        );
        vm.stopPrank();

        (string memory question, , , , , ,) = quereum.view_question(0);
        assertEq(question, "What is the best CS course at UCSB?");
    }

    // Test that users can endorse a question.
    // The app should update the reward of the correct question.
    function test_endorse_question() public {
        test_local_host_balance(); // Continue from last time.

        vm.startPrank(bob);
        quereum.endorse_question(0, 5 ether);
        vm.stopPrank();

        (, , , , uint256 reward, ,) = quereum.view_question(0);
        assertEq(reward, 25 ether);
    }
    
    // Test that users can answer a question.
    function test_answer_question() public {
        test_endorse_question(); // Continue from last time.

        vm.startPrank(eve);
        quereum.answer(0, "CS 190J!");
        vm.stopPrank();

        vm.startPrank(mallory);
        quereum.answer(0, "CS 130A.");
        vm.stopPrank();
    }

    // Test that users can endorse an answer.
    function test_endorse_answer() public {
        test_answer_question(); // Continue from last time.

        vm.startPrank(bob);
        quereum.endorse_answer(0);
        vm.stopPrank();
    }

    // Test that users can claim rewards.
    // The contract should send back the reward to be added
    // to the true balance of the user.
    function test_claim_reward() public {
        test_endorse_answer(); // Continue from last time.

        skip(1200); // Skip to question expiry time.

        assert(quereum.expired(0));

        vm.startPrank(eve);
        quereum.claim_reward();
        vm.stopPrank();

        assertEq(address(eve).balance, 125 ether);
    }

}