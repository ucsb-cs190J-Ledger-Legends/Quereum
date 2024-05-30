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

    struct Answer {
        string answer; // answer text
        address author; // user that posted the answer
        uint256 endorsements; // count of endorsements for the answer
        address[] endorsed_by; // address to users who endorsed answer
        uint256 question_index; // index to question being answered
    }

    // Mapping of user addresses to their names/balances/questions
    mapping(address => string) private accounts;
    mapping(address => uint256) private balances;
    Question[] private questions;
    mapping(address => uint256[]) private userQuestions;

    Answer[] private answers;
    mapping(address => uint256[]) private userAnswers;

    // Answer question posted by user
    function answer(
        uint256 question_index,
        string memory response
    ) public returns (bool) {
        uint256 question_status = questions[question_index].status;
        // check if question is closed or expired
        if (question_status == 1 || question_status == 2) return false;

        // get answer indices associated with respondent
        uint256[] memory answer_indices = userAnswers[msg.sender];

        //check if respondent has already answered the question
        for (uint256 i = 0; i < answer_indices.length; i++) {
            if (answers[answer_indices[i]].question_index == question_index)
                return false; // respondent already asnwered question
        }

        Answer memory answer_ = Answer({
            answer: response,
            author: msg.sender,
            endorsements: 0,
            endorsed_by: new address[](0),
            question_index: question_index
        });
        answers.push(answer_);
        uint256 answer_index = answers.length - 1;
        questions[question_index].responses.push(answer_index);
        userAnswers[msg.sender].push(answer_index);
        return true; // successfully answered questioned
    }

    // Endorse an answer posted by user
    function endorse_answer(uint256 answer_index) public returns (bool) {
        uint256 question_status = questions[
            answers[answer_index].question_index
        ].status;
        // check if question is closed or expired
        if (question_status == 1 || question_status == 2) return false;

        // check if endorser already endorsed answer
        for (uint256 i = 0; i < answers[answer_index].endorsed_by.length; i++) {
            if (answers[answer_index].endorsed_by[i] == msg.sender) {
                return false; // endorser already endorsed this answer
            }
        }

        answers[answer_index].endorsements++;
        answers[answer_index].endorsed_by.push(msg.sender);
        return true; // successfully endorsed answer
    }

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

        // deduct the reward from the user's balance
        balances[msg.sender] -= reward;

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

    // View question details
    function view_question(
        uint256 questionId
    )
        public
        view
        returns (
            string memory,
            uint256,
            uint256,
            address,
            uint256,
            uint256[] memory,
            bool
        )
    {
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

    // Endorse a question.
    function endorse_question(
        uint256 questionId,
        uint256 amount
    ) public returns (bool) {
        require(bytes(accounts[msg.sender]).length > 0, "User not registered");
        require(amount > 0, "Amount must be greater than 0");
        require(questions[questionId].status == 0, "Question is not active");
        require(
            questions[questionId].expirationTime > block.timestamp,
            "Question has expired"
        );
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;
        questions[questionId].reward += amount;

        return true;
    }
}
