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
}
