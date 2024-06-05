# Quereum

Our team, Ledger Legends, designed a smart contract application called Quereum that utilizes Ethereum blockchain technology and Solidity to create a Q&A system that allows users to post questions and also allows the user to reward the best answers with ether. The system allows for interaction from other users to vote for the best answers, an incentive for other users to post good and thoughtful answers in order to get the reward. Our goals were to incentivize user participation while also maintaining security of user balances.

## Set Up and Initialization

To set up the testing environment for Quereum, you will need to have installed the Foundry toolset for Solidity programming. In particular, you will need to be able to use the `forge` terminal command.

Download this repository, and then, using the terminal, navigate to the directory where the repository was downloaded. Then, running the command `forge test` will run all the test cases for Quereum.

To use the application for yourself, look through the `test/` directory for examples of how the runthrough is written. Then, create a new file in the `test/` directory with extension `.t.sol`. Create a new contract with a function whose name starts with `test_`, and use the API calls (see below) to test run features of the application.

## Primary Components

[TO ADD]

## User Roles

When designing Quereum, our team has tried to maintain the highest level of accessibility among all users. For this reasons, once a user registers with our smart contract (see how to do so in the API section), the user has access to every functionality in the contract, from posting questions, answering questions, endorsing questions, and endorsing answers. Users do not have to "apply" for a question asker role or an answerer role as they may need to do in other applications.

## Application Programming Interface