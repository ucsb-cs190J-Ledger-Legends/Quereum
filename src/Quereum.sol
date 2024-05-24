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
        address [] endorsed_by; // address to users who endorsed answer
        uint256 question_index; // index to question being answered
    }

    // Mapping of user addresses to their names/balances/questions/answers
    mapping(address => string) private accounts;
    mapping(address => uint256) private balances;
    Question[] private questions;
    mapping(address => uint256[]) private userQuestions;
    Answer[] private answers;
    mapping(address => uint256[]) private userAnswers;

    // Answer question posted by user
    function answer(uint256 question_index, string memory response, address respondent) public returns (bool) {
        // get answer indices associated with respondent
        uint256[] memory answer_indices = userAnswers[respondent];

        //check if respondent has already answered the question
        for (uint256 i = 0; i < answer_indices.length; i++){
            if(answers[answer_indices[i]].question_index == question_index) return false; // respondent already asnwered question
        }

        Answer memory answer_ = Answer({
            answer: response,
            author: respondent,
            endorsements: 0,
            endorsed_by: new address[](0),
            question_index: question_index
        });
        answers.push(answer_);

        return true; // successfully answered questioned
    }

}
