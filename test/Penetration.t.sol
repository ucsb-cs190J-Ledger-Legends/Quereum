// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "lib/forge-std/src/Test.sol";
import "lib/forge-std/src/Vm.sol";
import {Quereum} from "src/Quereum.sol";

contract PenetrationTest is Test {
    Quereum public quereum;

    // ===================== //
    // ==== local roles ==== //
    // ===================== //

    address public alice = address(0x01);
    address public bob = address(0x02);
    address public eve = address(0x03);
    address public mallory = address(0x04);

    function setUp() public {
        deal(alice, 100 ether);
        deal(bob, 100 ether);
        deal(eve, 100 ether);
        deal(mallory, 100 ether);
        
        quereum = new Quereum();
    }

    // ========================== //
    // ==== local test cases ==== //
    // ========================== //

    // Test if alice can post a question without registering.
    // The app should revert the transaction.
    // If a user could interact with our app without registering,
    // we would not be able to track malicious actions (such as
    // endorsing a question multiple times).
    function test_no_registration() public {
        vm.startPrank(alice);
        vm.expectRevert("User not registered");
        quereum.postQuestion(
            "Can I post a question without registering?",
            block.timestamp + 1000,
            0 ether
        );
        vm.stopPrank();
    }

    // Test if alice can post a question without adding balance.
    // The app should revert the transaction.
    // If a user could use our app without actually sending balances,
    // there's no way to ensure that the user will send over the
    // reward to the best responder, or worse, use our contract's
    // money as the reward instead of alice's.
    function test_no_balance() public {
        vm.startPrank(alice);
        quereum.register("Alice");

        vm.expectRevert("Insufficient balance for reward");
        quereum.postQuestion(
            "Can I post a question without balance?",
            block.timestamp + 1000,
            10 ether
        );
        vm.stopPrank();
    }

    // Test if alice can post multiple quesitons using the same
    // balance.
    // The app should revert the second question.
    // If alice could do this, then this would allow for double
    // spending, and our contract could lose ETH to make up for
    // this.
    function test_one_balance_multiple_questions() public {
        vm.startPrank(alice);
        quereum.register("Alice");
        quereum.addBalance{value: 10 ether}();

        quereum.postQuestion(
            "Can I post a question?",
            block.timestamp + 1000,
            10 ether
        );

        vm.expectRevert("Insufficient balance for reward");
        quereum.postQuestion(
            "Can I post another question with the same balance?",
            block.timestamp + 1000,
            10 ether
        );
        vm.stopPrank();
    }

    // Test if bob can endorse a question with the same balance.
    // The app should revert the second endorsement.
    // If bob could do this, then this would allow for double
    // spending, and our contract could lose ETH to make up for
    // this.
    function test_one_balance_multiple_question_endorsements() public {
        vm.startPrank(alice);
        quereum.register("Alice");
        quereum.addBalance{value: 10 ether}();

        quereum.postQuestion(
            "Can you endorse me twice?",
            block.timestamp + 1000,
            10 ether
        );
        vm.stopPrank();

        vm.startPrank(bob);
        quereum.register("Bob");
        quereum.addBalance{value: 1 ether}();

        quereum.endorse_question(0, 1 ether);

        vm.expectRevert("Insufficient balance");
        quereum.endorse_question(0, 1 ether);
        vm.stopPrank();
    }

    // Test if eve can endorse an answer multiple times.
    // The second endorsement should return false.
    // If eve could endorse an answer multiple times, eve
    // could singlehandedly determine which answer gets
    // the reward.
    function test_multiple_answer_endorsements() public {
        vm.startPrank(alice);
        quereum.register("Alice");
        quereum.addBalance{value: 10 ether}();

        quereum.postQuestion(
            "Can you endorse an answer twice?",
            block.timestamp + 1000,
            10 ether
        );
        vm.stopPrank();

        vm.startPrank(bob);
        quereum.register("Bob");

        quereum.answer(0, "Try it. It shouldn't work.");
        vm.stopPrank();

        vm.startPrank(eve);
        quereum.register("Eve");

        assert(quereum.endorse_answer(0));
        assertFalse(quereum.endorse_answer(0));
        vm.stopPrank();
    }

    // Test if alice can close a question without reward simply
    // to retrieve bob's endorsement as profit.
    // alice's balance should not have the increased reward.
    // If alice could close a question without rewarding just to
    // claim endorsements, the point of endorsements (rewarding
    // the best answer) is defeated, and endorsers are less
    // incentivized to endorse future questions.
    function test_endorsement_profiteering() public {
        vm.startPrank(alice);
        quereum.register("Alice");
        quereum.addBalance{value: 10 ether}();

        quereum.postQuestion(
            "Can you endorse me?",
            block.timestamp + 1000,
            10 ether
        );
        vm.stopPrank();

        vm.startPrank(bob);
        quereum.register("Bob");
        quereum.addBalance{value: 1 ether}();

        quereum.endorse_question(0, 1 ether);
        vm.stopPrank();

        vm.startPrank(alice);
        quereum.close_without_reward(0);

        (, uint256 alice_bal) = quereum.viewUserDetails();
        assertEq(alice_bal, 0 ether);
        vm.stopPrank();
    }

    // Test posting a question with an expiry date in the past.
    // The question post should revert.
    // If a user can post a question with an expiry date in the
    // past, then nobody would be able to answer and earn
    // rewards from that question, defeating Quereum's purpose.
    function test_past_expiration_date() public {
        vm.startPrank(alice);
        quereum.register("Alice");
        quereum.addBalance{value: 10 ether}();

        vm.expectRevert("Invalid expiration time");
        quereum.postQuestion(
            "Can I post a question with an expiration date in the past?",
            block.timestamp - 1,
            10 ether
        );
        vm.stopPrank();
    }

    // Test posting a question with an overflowed expiry date.
    // The question post should work, but because we ask for a
    // timestamp and not a duration, it should be impossible
    // to expire immediately.
    // If a user can overflow the expiration date, then they
    // could expire the question immediately, meaning nobody
    // could earn rewards from that question.
    function test_overflow_expiration_date() public {
        vm.startPrank(alice);
        quereum.register("Alice");
        quereum.addBalance{value: 10 ether}();

        quereum.postQuestion(
            "Can I post a question with a really large expiration date?",
            type(uint256).max,
            10 ether
        );

        assertFalse(quereum.expired(0));
        vm.stopPrank();
    }

    // Test if bob can answer a question after it expires
    // but before rewards have been allocated.
    // The answer function should return false.
    // If a user could answer a question after it expires
    // but before rewards have been allocated, this defeats
    // the point of an expiration date in the first place,
    // and our data structures would be holding unnecessary
    // answers, increasing gas fees.
    function test_answer_after_expiry() public {
        vm.startPrank(alice);
        quereum.register("Alice");
        quereum.addBalance{value: 10 ether}();

        quereum.postQuestion(
            "Can you answer a question after it expires?", 
            block.timestamp + 1000,
            10 ether
        );
        vm.stopPrank();

        skip(1200);

        vm.startPrank(bob);
        quereum.register("Bob");

        assertFalse(quereum.answer(0, "No, you can't."));
        vm.stopPrank();
    }

    // Test if eve can endorse an answer after the question
    // expires but before rewards have been allocated.
    // The endorse answer function should return false.
    // If a user could endorse an answer after the question
    // expires but before rewards have been allocated, they
    // could manipulate who wins the reward even though the
    // original asker intends for the question to be closed.
    function test_endorse_answer_after_expiry() public {
        vm.startPrank(alice);
        quereum.register("Alice");
        quereum.addBalance{value: 10 ether}();

        quereum.postQuestion(
            "Can you endorse an answer after this expires?", 
            block.timestamp + 1000,
            10 ether
        );
        vm.stopPrank();

        vm.startPrank(bob);
        quereum.register("Bob");

        quereum.answer(0, "No, you can't. Try and see.");
        vm.stopPrank();

        skip(1200);

        vm.startPrank(eve);
        quereum.register("Eve");

        assertFalse(quereum.endorse_answer(0));
        vm.stopPrank();
    }

    // Test if a contract can re-enter the claim reward function.
    // The transaction should revert.
    // If re-entrancy worked, then a malicious contract could
    // claim the same reward again and again until all our balance is
    // drained.
    function test_re_entrancy() public {
        ReEnterer reEnterer = new ReEnterer();
        deal(address(reEnterer), 100 ether);

        vm.expectRevert("Ether was not received properly.");
        reEnterer.addAndRemoveBalance(quereum);
    }

    // Test if a contract can use Quereum without an implemented
    // fallback.
    // The contract should still be able to interact with Quereum;
    // it simply cannot claim the reward. Also, this shouldn't 
    // affect other users' ability to claim rewrad.
    // If a no fallback contract could impede other users from 
    // claiming rewards, then this would disincentivize people from
    // using our contract.
    function test_no_fallback() public {
        NoFallback noFallback = new NoFallback();
        deal(address(noFallback), 100 ether);

        vm.startPrank(alice);
        quereum.register("Alice");
        quereum.addBalance{value: 10 ether}();

        quereum.postQuestion(
            "How do I test a contract from the perspective of a user?",
            block.timestamp + 1000, 
            10 ether
        );
        vm.stopPrank();

        vm.startPrank(bob);
        quereum.register("Bob");

        quereum.answer(0, "Use vm.startPrank().");
        vm.stopPrank();

        noFallback.registerAndAnswer(quereum, 0);

        vm.startPrank(eve);
        quereum.register("Eve");

        quereum.endorse_answer(0);
        quereum.endorse_answer(1);
        vm.stopPrank();

        skip(1200);

        // At this point, both answers have the same number
        // of endorsements, so they should split the reward.

        assert(quereum.expired(0));

        vm.startPrank(bob);
        (, uint256 bob_bal) = quereum.viewUserDetails();
        assertEq(bob_bal, 5 ether);
        vm.stopPrank();

        noFallback.checkBalance(quereum, 5 ether);

        // Bob should be able to claim his reward.

        vm.startPrank(bob);
        quereum.claim_reward();
        vm.stopPrank();

        assertEq(address(bob).balance, 105 ether);

        // Even though noFallback cannot claim its reward.

        vm.expectRevert("Ether was not received properly.");
        noFallback.claimReward(quereum);
    }

    // Test a forced ether transfer from selfdestruct.
    // Quereum should still work as expected, and no
    // user balances should be updated.
    // If forced ether transfers changed how balances
    // worked in Quereum, malicious users could send
    // ether in ways that create denial of service for
    // other users.
    function test_self_destruct() public {
        vm.startPrank(alice);
        quereum.register("Alice");
        quereum.addBalance{value: 10 ether}();

        SelfDestructor selfDestructor = new SelfDestructor();
        payable(address(selfDestructor)).call{value: 10 ether}("");
        selfDestructor.destruct(quereum);

        (, uint256 alice_bal) = quereum.viewUserDetails();
        assertEq(alice_bal, 10 ether);

        quereum.claim_reward();
        vm.stopPrank();

        assertEq(address(alice).balance, 90 ether);
    }
}

contract ReEnterer {

    Quereum quereum;
    bool hasReEntered;

    function addAndRemoveBalance(Quereum _quereum) public {
        quereum = _quereum;
        hasReEntered = false;

        quereum.register("ReEnterer");
        quereum.addBalance{value: 10 ether}();
        quereum.claim_reward();
    }

    fallback() external payable {
        if (!hasReEntered) {
            hasReEntered = true;
            quereum.claim_reward();
        }
    }
}

contract NoFallback {

    function registerAndAnswer(Quereum quereum, uint256 q_index) public {
        quereum.register("NoFallback");

        quereum.answer(q_index, "Use hoax().");
    }

    function checkBalance(Quereum quereum, uint256 expected_bal) public {
        (, uint256 true_bal) = quereum.viewUserDetails();
        assert(expected_bal == true_bal);
    }

    function claimReward(Quereum quereum) public {
        quereum.claim_reward();
    }
}

contract SelfDestructor {

    function destruct(Quereum quereum) public {
        selfdestruct(payable(address(quereum)));
    }

    fallback() external payable {}
}