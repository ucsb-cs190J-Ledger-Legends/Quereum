// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Quereum} from "../src/Quereum.sol";

contract QuereumTest is Test {
    Quereum private quereum;

    address private user1 = address(0x1);
    address private user2 = address(0x2);

    function setUp() public {
        quereum = new Quereum();
    }

    // testing user registration
    function testRegisterUser() public {
        // register user1 with name Alice
        bool result = quereum.register(user1, "Alice");
        assertTrue(result, "User registration should succeed");

        // impersonate user1 to view user details and check if name and balance are correct
        hoax(user1);
        (string memory name, uint256 balance) = quereum.viewUserDetails();
        assertEq(name, "Alice", "User name should be Alice");
        assertEq(balance, 0, "User balance should be 0");
    }

    // testing adding balance
    function testAddBalance() public {
        quereum.register(user1, "Alice"); // register user1

        hoax(user1); // impersonate user1
        bool result = quereum.addBalance{value: 1 ether}(); // add 1 ether to user1's balance
        assertTrue(result, "Adding balance should succeed"); // check if adding balance succeeded

        // impersonate user1 to view user details and check if balance is correct
        hoax(user1);
        (, uint256 balance) = quereum.viewUserDetails();
        assertEq(balance, 1 ether, "User balance should be 1 ether");
    }

    // testing posting a question
    function testPostQuestion() public {
        hoax(user1);
        quereum.register(user1, "Alice");
        hoax(user1);
        quereum.addBalance{value: 10 ether}();
        // impersonate user1 to view user details and check if balance is correct
        hoax(user1);
        (, uint256 balanceCheck) = quereum.viewUserDetails();
        assertEq(
            balanceCheck,
            10 ether,
            "User balance should be 10 ether after adding it"
        );

        // post a question with 0.1 ether reward and expiration time 1 day from now
        hoax(user1);
        bool result = quereum.postQuestion(
            "What is Solidity?",
            block.timestamp + 1 days,
            1 ether
        );
        assertTrue(result, "Posting question should succeed");

        // impersonate user1 to view user details and check if balance is correct
        hoax(user1);
        (, uint256 balance) = quereum.viewUserDetails();
        assertEq(
            balance,
            9 ether,
            "User balance should be 9 ether after posting question with 1 ether reward"
        );
    }

    // test posting a question with insufficient balance
    function testPostQuestionInsufficientBalance() public {
        // register user1 with name Alice
        quereum.register(user1, "Alice");

        // impersonate user1 to add 0.05 ether to user1's balance and post a question with 0.1 ether reward
        hoax(user1);
        quereum.addBalance{value: 1 ether}();

        vm.expectRevert("Insufficient balance for reward");
        hoax(user1);
        quereum.postQuestion(
            "What is Solidity?",
            block.timestamp + 1 days,
            3 ether
        );
    }

    // test posting a question with invalid expiration time
    function testPostQuestionInvalidExpiration() public {
        // register user1 with name Alice
        quereum.register(user2, "Bob");

        // impersonate user1 to add 1 ether to user1's balance
        hoax(user2);
        quereum.addBalance{value: 1 ether}();

        // post a question with 0.1 ether reward and expiration time 1 day in the past
        hoax(user2);
        vm.expectRevert("Invalid expiration time");

        quereum.postQuestion(
            "What is Solidity?",
            block.timestamp - 1 seconds,
            1 ether
        );
    }

    // test duplicate registration
    function testDuplicateRegistration() public {
        quereum.register(user1, "Alice");

        // try to register user1 again
        vm.expectRevert("User already registered");
        quereum.register(user1, "AliceAgain");
    }

    // test view user details
    function testViewUserDetails() public {
        quereum.register(user1, "Alice");

        // impersonate user1 to view user details and check if name and balance are correct
        hoax(user1);
        (string memory name, uint256 balance) = quereum.viewUserDetails();
        assertEq(name, "Alice", "User name should be Alice");
        assertEq(balance, 0, "User balance should be 0");
    }
}
