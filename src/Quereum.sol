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
    function addBalance(uint256 amount) public returns (bool) {
        require(bytes(accounts[msg.sender]).length > 0, "User not registered");
        balances[msg.sender] += amount;
        return true;
    }

    // helper function to calculate the total locked reward for a user
    function getTotalLockedReward(
        address userAddress
    ) internal view returns (uint256) {
        uint256 totalLockedReward = 0;
        // get the ids of all questions posted by the user
        uint256[] memory userQuestionIds = userQuestions[userAddress];

        for (uint256 i = 0; i < userQuestionIds.length; i++) {
            Question storage question = questions[userQuestionIds[i]]; // get the question
            if (question.status == 0 && !question.rewardAllocated) {
                totalLockedReward += question.reward; // add the reward to the total locked reward
            }
        }

        return totalLockedReward;
    }

    // post a new question with a reward
    function postQuestion(
        string memory questionText,
        uint256 expirationTime,
        uint256 reward
    ) public returns (bool) {
        require(bytes(accounts[msg.sender]).length > 0, "User not registered");

        // calculate all the rewards in the questionst the user posted to ensure they have a sufficient balance
        uint256 totalLockedReward = getTotalLockedReward(msg.sender);
        require(
            balances[msg.sender] >= totalLockedReward + reward,
            "Insufficient balance for reward"
        );

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

        return true;
    }

    // View user details
    function viewUserDetails() public view returns (string memory, uint256) {
        return (accounts[msg.sender], balances[msg.sender]);
    }

    // View a question
    function view_question(uint256 questionId) public view returns (string memory, uint256, uint256, address, uint256, uint256[] memory, bool) {
        Question storage question = questions[questionId];
        return (
            question.question,
            question.expirationTime,
            question.status,
            question.user,
            question.reward,
            question.responses,
            question.rewardAllocated
        );
    }

    // Endorse a question. This will take a uint256 index of the question and will take the msg.value and increment the reward of the question by that amount
    function endorse_question(uint256 questionId, uint256 amount) public returns (bool) {
        require(bytes(accounts[msg.sender]).length > 0, "User not registered");
        require(amount > 0, "Amount must be greater than 0");
        require(questions[questionId].status == 0, "Question is not active");
        require(questions[questionId].expirationTime > block.timestamp, "Question has expired");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;
        questions[questionId].reward += amount;

        return true;
    }
}
