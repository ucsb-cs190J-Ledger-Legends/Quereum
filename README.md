# Quereum

Quereum is a decentralized question and answer platform based on smart contracts. It allows users to post questions with rewards, answer questions, and endorse answers. The platform operates using Ethereum smart contracts to ensure transparency and security.

## APIs of the Application

### Register a New User
**Function**: `register(string memory name)`

**Description**: Registers a new user with a chosen name.

**Returns**: `bool` indicating success.

**Security Note**: Ensure that the user is not already registered.

### Add Balance to User Account
**Function**: `addBalance()`

**Description**: Adds balance to the user's account.

**Returns**: `bool` indicating success.

**Security Note**: Ensure the user is registered before adding balance. Balance added with msg.value.

### Post a New Question
**Function**: `postQuestion(string memory questionText, uint256 expirationTime, uint256 reward)`

**Description**: Posts a new question with a specified reward and expiration time.

**Returns**: `bool` indicating success.

**Security Note**: Ensure the user has sufficient balance and valid expiration time.

### Answer a Question
**Function**: `answer(uint256 question_index, string memory response)`

**Description**: Answers a posted question.

**Returns**: `bool` indicating success.

**Security Note**: Ensure the question is active and the user hasn't already answered it.

### Endorse an Answer
**Function**: `endorse_answer(uint256 answer_index)`

**Description**: Endorses an answer to a question.

**Returns**: `bool` indicating success.

**Security Note**: Ensure the user hasn't already endorsed the answer and the question is active.

### View User Details
**Function**: `viewUserDetails()`

**Description**: Returns the details of the user (name and balance).

**Returns**: `(string memory, uint256)` containing the user's name and balance.

### View Question Details
**Function**: `view_question(uint256 questionId)`

**Description**: Returns the details of a specific question.

**Returns**: 
```solidity
(string memory, uint256, uint256, address, uint256, uint256[] memory, bool)
