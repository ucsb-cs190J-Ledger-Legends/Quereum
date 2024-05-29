// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Quereum {
    struct Question {
        string question; // the actual question text
        uint256 expirationTime; // let's use UTC time?
        uint256 status; // 0 for active 1 for expired 2 for closed
        address user; // address of the user who posted the question
        uint256 reward; // reward for answering the question
        uint256[] responses; // array of response ids
        bool rewardAllocated; // if the reward has been allocated or not
    }

    // Mapping of user addresses to their names/balances/questions
    mapping(address => string) private accounts;
    mapping(address => uint256) private balances;
    Question[] private questions;
    mapping(address => uint256[]) private userQuestions;

    // Register a new user with a chosen name
    function register(
        address userAddress,
        string memory name
    ) public returns (bool) {
        require(
            bytes(accounts[userAddress]).length == 0,
            "User already registered"
        );
        accounts[userAddress] = name;
        balances[userAddress] = 0; // initialize balance to 0
        return true;
    }

    // add balance to the user's account
    function addBalance() public payable returns (bool) {
        require(bytes(accounts[msg.sender]).length > 0, "User not registered");
        balances[msg.sender] += msg.value;
        return true;
    }

    // post a new question with a reward
    function postQuestion(
        string memory questionText,
        uint256 expirationTime,
        uint256 reward
    ) public returns (bool) {
        require(bytes(accounts[msg.sender]).length > 0, "User not registered");

        // make sure user has sufficient balance for question reward
        require(
            balances[msg.sender] >= reward,
            "Insufficient balance for reward"
        );

        // make sure expiration time is after the current time
        require(expirationTime > block.timestamp, "Invalid expiration time");

        Question memory newQuestion = Question({
            question: questionText, // the question text
            expirationTime: expirationTime, // the expiration time
            status: 0, // status is active
            user: msg.sender, // the user posting the question
            reward: reward, // the reward for the question
            responses: new uint256[](0), // initializing responses array
            rewardAllocated: false // reward not allocated yet
        });

        // add the question to the array of questions and the user's questions
        questions.push(newQuestion);
        userQuestions[msg.sender].push(questions.length - 1);

        // deduct the reward from the user's balance
        balances[msg.sender] -= reward;

        return true;
    }

    // View user details
    function viewUserDetails() public view returns (string memory, uint256) {
        return (accounts[msg.sender], balances[msg.sender]);
    }
}
