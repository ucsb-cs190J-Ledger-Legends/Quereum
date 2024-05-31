// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "lib/forge-std/src/Test.sol";
import "forge-std/Vm.sol";
import {Quereum} from "src/Quereum.sol";

contract RewardSpecialCasesTest is Test {
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

        vm.startPrank(alice);
        quereum.register("alice");
        quereum.addBalance{value: 10 ether}();
        quereum.postQuestion(
            "How to change block.timstamp in Solidity?",
            block.timestamp + 1000,
            10 ether
        );
        vm.stopPrank();

        vm.startPrank(bob);
        quereum.register("bob");
        vm.stopPrank();

        vm.startPrank(eve);
        quereum.register("eve");
        vm.stopPrank();

        vm.startPrank(mallory);
        quereum.register("mallory");
        vm.stopPrank();
    }

    function setup_responses() public {
        vm.startPrank(eve);
        quereum.answer(0, "Use vm.warp().");
        vm.stopPrank();

        vm.startPrank(mallory);
        quereum.answer(0, "Use skip().");
        vm.stopPrank();

        vm.startPrank(bob);
        quereum.endorse_answer(0);
        quereum.endorse_answer(1);
        vm.stopPrank();
    }

    // ========================== //
    // ==== local test cases ==== //
    // ========================== //

    // CLOSE WITHOUT REWARDING
        // SPLIT REWARDS
        // NOBODY RESPONDS

    // Test that alice can close without rewarding.
    function test_close_without_reward() public {
        setup_responses();

        vm.startPrank(alice);
        quereum.close_without_reward(0);
        vm.stopPrank();

        skip(1200);

        assert(quereum.expired(0));

        vm.startPrank(eve);
        (, uint256 eve_bal) = quereum.viewUserDetails();
        assertEq(eve_bal, 0 ether);
        vm.stopPrank();

        vm.startPrank(mallory);
        (, uint256 mallory_bal) = quereum.viewUserDetails();
        assertEq(mallory_bal, 0 ether);
        vm.stopPrank();
    }

    // Test that two answers with equal endorsements
    // split the reward.
    function test_split_reward() public {
        setup_responses();
        skip(1200);

        assert(quereum.expired(0));

        vm.startPrank(eve);
        (, uint256 eve_bal) = quereum.viewUserDetails();
        assertEq(eve_bal, 5 ether);
        vm.stopPrank();

        vm.startPrank(mallory);
        (, uint256 mallory_bal) = quereum.viewUserDetails();
        assertEq(mallory_bal, 5 ether);
        vm.stopPrank();
    }

    // Test that if nobody responds, the ether should
    // go back to alice.
    function test_no_response() public {
        skip(1200);

        assert(quereum.expired(0));

        vm.startPrank(alice);
        (, uint256 alice_bal) = quereum.viewUserDetails();
        assertEq(alice_bal, 10 ether);
        vm.stopPrank();
    }

}