// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Quereum {

    mapping(address => uint256) private balances; // The balance of each user.

    // This function allows a user to claim any reward
    // balance the app owns them.
    function claim_reward() public {
        require(balances[msg.sender] > 0, "No reward to claim.");

        uint256 amountToSend = balances[msg.sender];
        balances[msg.sender]; // Reset to prevent re-entrancy.

        (bool confirmation, ) = msg.sender.call{value: amountToSend}("");
        require(confirmation, "Ether was not received properly.")
    }

    // This function checks whether or not the question at that
    // index is expired. If it should be, it changes the necessary
    // struct variables. It returns true if the question is expired.
    function expired(uint256 question_index) public {

        // If the function is already closed, we don't need
        // to do anything.
        if (questions[question_index].status == 2) {
            return true;
        }

        // If the function is open, check whether or not
        // it should be expired.
        if (questions[question_index].status == 0) {

            if (questions[question_index].expirationTime >= block.timestamp) {
                questions[question_index].status = 1;
            }

            else {
                return false;
            }
        }

        // If the function is expired but not closed,
        // assign rewards.
        if (questions[question_index].status == 1) {

            uint256 max_endorsements = -1;
            address[] most_endorsed_authors = [];

            // Traverse through all the answers for this question.
            for (uint256 response_index = 0;
                response_index < questions[question_index].responses.length;
                response_index++) {
                
                address_index = questions[question_index].responses[response_index];

                if (answers[answer_index].endorsements > max_endorsements) {
                    max_endorsements = answers[answer_index].endorsements;
                    most_endorsed_authors = [answers[answer_index].author];
                }

                else if (answers[answer_index].endorsements == max_endorsements) {
                    most_endorsed_authors.push(answers[answer_index].author);
                }
            }

            // If max_endorsements is still -1, nobody answered the
            // question, so do nothing. Otherwise, remove the reward
            // from the questioner and add it to the recipients.
            if (max_endorsements != -1) {
                uint256 reward = questions[question_index].reward;
                balances[questions[question_index].user] -= reward;

                uint256 allocation = reward / most_endorsed_authors.length;

                for (uint256 i = 0; i < most_endorsed_authors.length; i++) {
                    balances[most_endorsed_authors[i]] += allocation;
                }
            }

            questions[question_index].rewardAllocated = true;

        }

        return true;
    }
}
