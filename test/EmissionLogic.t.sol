// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { console2 } from "forge-std/console2.sol";
import { PRBTest } from "prb-test/PRBTest.sol";
import { StdCheats } from "forge-std/StdCheats.sol";

import "../src/EmissionLogic.sol";

contract EmissionLogicTest is PRBTest, StdCheats {
    EmissionLogic logic;
    address testAddress = 0x1234567890123456789012345678901234567890;

    function setUp() public {
        logic = new EmissionLogic();
    }

    function test_determineTokenIdV1_100001() public {
        // Set block.prevrandao
        uint256 prevrandao = 44;
        vm.prevrandao(bytes32(prevrandao));

        // Set block.timestamp
        uint256 timestamp = 1_641_070_801;
        vm.warp(timestamp);

        // Set msg.sender
        vm.prank(testAddress);

        uint256 tokenId = logic.determineTokenByLogic(1);
        console2.log("tokenId: ", tokenId);
        // Check if the returned tokenId is as expected
        assertEq(tokenId, 100_001);
    }

    function test_determineTokenIdV1_100002() public {
        // Set block.prevrandao
        uint256 prevrandao = 43;
        vm.prevrandao(bytes32(prevrandao));

        // Set block.timestamp
        uint256 timestamp = 1_641_070_800;
        vm.warp(timestamp);

        // Set msg.sender
        vm.prank(testAddress);

        uint256 tokenId = logic.determineTokenByLogic(1);
        // Check if the returned tokenId is as expected
        assertEq(tokenId, 100_002);
    }

    function test_determineTokenIdV1_100003() public {
        // Set block.prevrandao
        uint256 prevrandao = 42;
        vm.prevrandao(bytes32(prevrandao));

        // Set block.timestamp
        uint256 timestamp = 1_641_070_802;
        vm.warp(timestamp);

        // Set msg.sender
        vm.prank(testAddress);

        uint256 tokenId = logic.determineTokenByLogic(1);
        // Check if the returned tokenId is as expected
        assertEq(tokenId, 100_003);
    }

    function test_determineTokenIdV2_100001() public {
        // Set block.prevrandao
        uint256 prevrandao = 34;
        vm.prevrandao(bytes32(prevrandao));

        // Set block.timestamp
        uint256 timestamp = 1_641_070_801;
        vm.warp(timestamp);

        // Set msg.sender
        vm.prank(testAddress);

        uint256 tokenId = logic.determineTokenByLogic(2);
        console2.log("tokenId: ", tokenId);
        // Check if the returned tokenId is as expected
        assertEq(tokenId, 100_001);
    }

    function test_determineTokenIdV2_100004() public {
        // Set block.prevrandao
        uint256 prevrandao = 44;
        vm.prevrandao(bytes32(prevrandao));

        // Set block.timestamp
        uint256 timestamp = 1_641_070_811;
        vm.warp(timestamp);

        // Set msg.sender
        vm.prank(testAddress);

        uint256 tokenId = logic.determineTokenByLogic(2);
        console2.log("tokenId: ", tokenId);
        // Check if the returned tokenId is as expected
        assertEq(tokenId, 100_004);
    }

    function test_determineTokenIdV3_100001() public {
        // Set block.prevrandao
        uint256 prevrandao = 34;
        vm.prevrandao(bytes32(prevrandao));

        // Set block.timestamp
        uint256 timestamp = 1_641_070_801;
        vm.warp(timestamp);

        // Set msg.sender
        vm.prank(testAddress);

        uint256 tokenId = logic.determineTokenByLogic(3);
        console2.log("tokenId: ", tokenId);
        // Check if the returned tokenId is as expected
        assertEq(tokenId, 100_001);
    }

    function test_determineTokenIdV3_100004() public {
        // Set block.prevrandao
        uint256 prevrandao = 46;
        vm.prevrandao(bytes32(prevrandao));

        // Set block.timestamp
        uint256 timestamp = 1_641_070_808;
        vm.warp(timestamp);

        // Set msg.sender
        vm.prank(testAddress);

        uint256 tokenId = logic.determineTokenByLogic(3);
        console2.log("tokenId: ", tokenId);
        // Check if the returned tokenId is as expected
        assertEq(tokenId, 100_004);
    }

    function test_determineTokenIdV3_100005() public {
        // Set block.prevrandao
        uint256 prevrandao = 46;
        vm.prevrandao(bytes32(prevrandao));

        // Set block.timestamp
        uint256 timestamp = 1_641_070_805;
        vm.warp(timestamp);

        // Set msg.sender
        vm.prank(testAddress);

        uint256 tokenId = logic.determineTokenByLogic(3);
        console2.log("tokenId: ", tokenId);
        // Check if the returned tokenId is as expected
        assertEq(tokenId, 100_005);
    }

    function test_determineTokenIdV3_100006() public {
        // Set block.prevrandao
        uint256 prevrandao = 46;
        vm.prevrandao(bytes32(prevrandao));

        // Set block.timestamp
        uint256 timestamp = 1_641_070_803;
        vm.warp(timestamp);

        // Set msg.sender
        vm.prank(testAddress);

        uint256 tokenId = logic.determineTokenByLogic(3);
        console2.log("tokenId: ", tokenId);
        // Check if the returned tokenId is as expected
        assertEq(tokenId, 100_006);
    }

    function test_determineTokenIdV3_100007() public {
        // Set block.prevrandao
        uint256 prevrandao = 40;
        vm.prevrandao(bytes32(prevrandao));

        // Set block.timestamp
        uint256 timestamp = 1_641_070_902;
        vm.warp(timestamp);

        // Set msg.sender
        vm.prank(testAddress);

        uint256 tokenId = logic.determineTokenByLogic(3);
        console2.log("tokenId: ", tokenId);
        // Check if the returned tokenId is as expected
        assertEq(tokenId, 100_007);
    }

    function testFail_determineTokenIdV3_100007() public {
        // Set block.prevrandao
        uint256 prevrandao = 44;
        vm.prevrandao(bytes32(prevrandao));

        // Set block.timestamp
        uint256 timestamp = 1_641_070_824;
        vm.warp(timestamp);

        // Set msg.sender
        vm.prank(testAddress);

        logic.determineTokenByLogic(4);
    }
}
