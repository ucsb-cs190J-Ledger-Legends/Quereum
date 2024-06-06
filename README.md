# Quereum

Our team, Ledger Legends, designed a smart contract application called Quereum that utilizes Ethereum blockchain technology and Solidity to create a Q&A system that allows users to post questions and also allows the user to reward the best answers with ether. The system allows for interaction from other users to vote for the best answers, an incentive for other users to post good and thoughtful answers in order to get the reward. Our goals were to incentivize user participation while also maintaining security of user balances.

## Set Up and Initialization

To set up the testing environment for Quereum, you will need to have installed the Foundry toolset for Solidity programming. In particular, you will need to be able to use the `forge` terminal command.

Download this repository, and then, using the terminal, navigate to the directory where the repository was downloaded. Then, running the command `forge test` will run all the test cases for Quereum.

To use the application for yourself, look through the `test/` directory for examples of how the runthrough is written. Then, create a new file in the `test/` directory with extension `.t.sol`. Create a new contract with a function whose name starts with `test_`, and use the API calls (see below) to test run features of the application.

## Primary Components

The primary components of the Quereum application are the questions and the answers. Both of them are represented by structs.

The `Question` struct is defined as follows:

```c
struct Question {
    string question; // the actual question text
    uint256 expirationTime; // the timestamp of the expiration time
    uint256 status; // 0 for active, 1 for expired, 2 for closed
    address user; // address of the user who posted the question
    uint256 reward; // reward for answering the question
    uint256[] responses; // array of response ids
    bool rewardAllocated; // if the reward has been allocated or not
}
```

The `Answer` struct is defined as follows:

```c
struct Answer {
    string answer; // answer text
    address author; // user that posted the answer
    uint256 endorsements; // count of endorsements for the answer
    address[] endorsed_by; // address to users who endorsed answer
    uint256 question_index; // index to question being answered
}
```

## User Roles

When designing Quereum, our team has tried to maintain the highest level of accessibility among all users. For this reasons, once a user registers with our smart contract (see how to do so in the API section), the user has access to every functionality in the contract, from posting questions, answering questions, endorsing questions, and endorsing answers. Users do not have to "apply" for a question asker role or an answerer role as they may need to do in other applications.

## Application Programming Interface

Here are the functions of Quereum that can be called to interact with the Q&A functionality.

Before calling these functions, you need access to the Quereum contract. In the test cases, you can create a new instance of the contract as follows:

```c++
Quereum quereum = new Quereum();
```

### User Registration and Management

To register yourself as a Quereum user, call the following function:

```c++
quereum.register("[username]");
```

The parameter is a string of the username you want to use in the application. The function will revert if the user is already registered. All future functions will revert if the user is not registered.

To add balance to your account, call the following function.

```c++
quereum.addBalance{value: [amt] ether}();
```

Send in the amount to add in ether as the value of the message.

To view user details, call the following function.

```c++
quereum.viewUserDetails();
```

This function returns a 2-tuple with the `string` username of the user and the `uint256` balance of the user.

### Question Management

To post a question, call the following function:

```c++
quereum.postQuestion(
    "[Question Text]",
    [expiration_timestamp],
    [reward_amount]
);
```

The function returns true if the question was successfully posted. The function will revert if the expiration time is invalid or if the user's balance is not sufficient to provide the reward.

Questions can be accessed by indexing into the question array, as follows:

```c++
quereum.view_question([question_index]);
```

The function returns all the variables of the `Question` struct as a 7-tuple. For information about what the struct contains, check the Primary Components section above.

A unique feature of our application is that users who think a question is great can endorse that question and thus increase the reward for answering that question. To endorse a question, call the following function:

```c++
quereum.endorse_question(
    [question_index],
    [endorsement_amount]
);
```

The function reverts if the user does not have sufficient balance or if the question is expired. Otherwise, the function returns `true`.

### Answer Management

To post an answer, call the following function:

```c++
quereum.answer(
    [question_index],
    "[Answer Text]"
);
```

The function returns `true` if the question was successfully posted. The function will revert if the expiration time is invalid or if the user's balance is not sufficient to provide the reward.

Answers can be accessed by indexing into the answer array, as follows:

```c++
quereum.view_answer([answer_index]);
```

The function returns all the variables of the `Answer` struct as a 5-tuple. For information about what the struct contains, check the Primary Components section above.

To endorse an answer (similar to upvoting an answer on Quora), call this function:

```c++
quereum.endorse_answer([answer_index]);
```

The function returns `false` if the question is expired. Otherwise, the function returns `true`.

### Reward Management

If, as the asker of a question, you want to close the question without rewarding any answers, call the following function:

```c++
quereum.close_without_reward([question_index]);
```

This function will close the question without assigning rewards or returning it to the original asker. The function will revert if someone other than the original asker is trying to close the question or if rewards have already been allocated.

To check if a question is expired, call the following function.

```c++
quereum.expired([question_index]);
```

This function returns `true` if and only if the function has already expired. Note that, since this function handles reward allocation, it must be called at least once before users can claim their rewards, as seen in the following snippet.

```c++
assert(quereum.expired([question_index]));
quereum.claim_reward();
```

The final function enables a user to retrieve the entire balance. It will revert if there is no balance to claim or if the ether cannot be sent properly (e.g. due to an unimplemented `fallback()`).