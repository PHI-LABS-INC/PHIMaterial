// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { console2 } from "forge-std/console2.sol";
import { PRBTest } from "prb-test/PRBTest.sol";
import { StdCheats } from "forge-std/StdCheats.sol";

import "../src/object/MaterialObject.sol";
import "../src/object/CraftableObject.sol";
import "../src/object/UGCCraftableObject.sol";

import "../src/CraftLogic.sol";
import "../src/UGCCraftLogic.sol";

import "../src/UGCCraftableObjectFactory.sol";

contract UGCCraftableObjectTest is PRBTest, StdCheats {
    MaterialObject materialObject;
    CraftableObject craftObject;
    UGCCraftableObject ugcObject;

    CraftLogic craftLogic;
    UGCCraftLogic ugcCraftLogic;

    UGCCraftableObjectFactory factoryContract;

    address admin = vm.addr(1);
    address tempPhiMap = address(0x123);
    address tempForwarder = address(0xd8253782c45a12053594b9deB72d8e8aB2Fca54c);
    address tempGelatoRelay = 0xd8253782c45a12053594b9deB72d8e8aB2Fca54c;
    address payable tempTreasury = payable(address(0xb7Caa0ed757bbFaA208342752C9B1c541e36a4b9));
    address testAddress = address(0x5037e7747fAa78fc0ECF8DFC526DcD19f73076ce);

    uint256 testTokenId = 1;
    string testTokenUri = "testURI";

    function setUp() public {
        vm.startPrank(admin);
        craftLogic = new CraftLogic(tempTreasury, tempGelatoRelay);
        ugcCraftLogic = new UGCCraftLogic(tempForwarder, tempGelatoRelay);
        materialObject = new MaterialObject(tempTreasury, tempPhiMap,address(craftLogic),address(ugcCraftLogic));
        materialObject.createObject(
            1, "DOYHTf8ommXdN7ls6ZubQZvxvBstgdWkPGBm081urvs", BaseObject.Size({ x: 1, y: 1, z: 1 }), tempTreasury
        );

        craftObject = new CraftableObject(tempTreasury, tempPhiMap, address(craftLogic),address(ugcCraftLogic));
        craftObject.createObject(
            1, "DOYHTf8ommXdN7ls6ZubQZvxvBstgdWkPGBm081urvs", BaseObject.Size({ x: 1, y: 1, z: 1 }), tempTreasury, 10
        );

        factoryContract = new UGCCraftableObjectFactory(address(craftLogic),address(ugcCraftLogic));
        ugcObject = UGCCraftableObjectFactory(factoryContract).createUGCCraftableObject("test", "ZaK");
        ugcObject.createObject(testTokenUri, 10);
        ugcObject.createObject(testTokenUri, 10);

        ugcCraftLogic.setUgcFactory(address(factoryContract));
        ugcCraftLogic.addToWhitelist(address(materialObject));
        ugcCraftLogic.addToWhitelist(address(craftObject));

        // Creating recipeid1
        BaseCraftLogic.Material[] memory materials = new BaseCraftLogic.Material[](1);
        materials[0] = BaseCraftLogic.Material(address(ugcObject), 1, 1);
        BaseCraftLogic.Artifacts[] memory artifacts = new BaseCraftLogic.Artifacts[](1);
        artifacts[0] = BaseCraftLogic.Artifacts(address(ugcObject), 2, 1);
        BaseCraftLogic.Catalyst memory catalyst =
            BaseCraftLogic.Catalyst(address(0), 0, 0, BaseCraftLogic.TokenType.ERC20);
        ugcCraftLogic.createRecipe(materials, artifacts, catalyst);
        ugcObject.setApprovalForUGCCrafting(2, 1, true);
        vm.stopPrank();
    }

    function testObjectCreation() public {
        assertEq(ugcObject.getTokenidCount(), 2, "tokenIdCount should be 1");
        vm.prank(admin);
        ugcObject.createObject(testTokenUri, 10);
        assertEq(ugcObject.uri(3), testTokenUri, "Token URI should match");
        assertEq(ugcObject.getTokenidCount(), 3, "tokenIdCount should be 2");
    }

    function testGetMaxClaimed() public {
        vm.prank(admin);
        ugcObject.createObject(testTokenUri, 10);
        assertEq(ugcObject.maxClaimable(2), 10, "maxClaimable should be 10");
    }

    function testGetObject() public {
        vm.startPrank(admin);
        ugcObject.createObject(testTokenUri, 10);
        ugcObject.getObject(admin, 2, 1);
        vm.stopPrank();

        assertEq(ugcObject.balanceOf(admin, 2), 1, "Balance should be 1");
    }

    function test_setMaxClaimableAndGetObject() public {
        vm.startPrank(admin);
        ugcObject.createObject(testTokenUri, 1);
        ugcObject.setMaxClaimable(2, 2);
        ugcObject.getObject(admin, 2, 2);
        vm.stopPrank();

        assertEq(ugcObject.balanceOf(admin, 2), 2, "Balance should be 2");
    }

    function testFail_getObject_OverMaxClaimed() public {
        vm.startPrank(admin);
        ugcObject.createObject(testTokenUri, 3);
        assertEq(ugcObject.maxClaimable(2), 3, "maxClaimable should be 1");
        ugcObject.getObject(admin, 2, 2);
        ugcObject.getObject(admin, 2, 2);
        vm.stopPrank();
    }

    function testFail_CraftableObjectOverMaxClaimed() public {
        vm.startPrank(admin);
        ugcObject.createObject(testTokenUri, 1);
        ugcObject.getObject(admin, 3, 1);
        ugcObject.getObject(admin, 3, 1);
        vm.stopPrank();
    }

    function testUseforCraft() public {
        vm.startPrank(admin);

        ugcObject.getObject(testAddress, 1, 1);
        vm.stopPrank();
        vm.prank(testAddress);
        ugcCraftLogic.craft(1);
        assertEq(ugcObject.balanceOf(testAddress, 1), 0, "Balance should be 0");
        assertEq(ugcObject.balanceOf(testAddress, 2), 1, "Balance should be 1");
    }

    function testUpdateRecipe() public {
        // Starting the prank with admin account
        vm.startPrank(admin);
        materialObject.getObject(testAddress, 1, 1);
        ugcObject.getObject(testAddress, 1, 1);

        // Updating the recipe
        uint256 recipeId = 1;
        BaseCraftLogic.Material[] memory materials = new BaseCraftLogic.Material[](1);
        materials[0] = BaseCraftLogic.Material(address(materialObject), 1, 1);
        BaseCraftLogic.Artifacts[] memory artifacts = new BaseCraftLogic.Artifacts[](1);
        artifacts[0] = BaseCraftLogic.Artifacts(address(ugcObject), 1, 1);
        BaseCraftLogic.Catalyst memory catalyst =
            BaseCraftLogic.Catalyst(address(ugcObject), 1, 1, BaseCraftLogic.TokenType.ERC1155);
        bool active = true;

        // Update the recipe
        ugcCraftLogic.updateRecipe(recipeId, materials, artifacts, catalyst, active);
        ugcObject.setApprovalForUGCCrafting(1, 1, true);
        // Stop the prank
        vm.stopPrank();

        vm.prank(testAddress);
        ugcCraftLogic.craft(1);

        assertEq(materialObject.balanceOf(testAddress, 1), 0, "Balance should be 0");
        assertEq(ugcObject.balanceOf(testAddress, 1), 2, "Balance should be 2");
    }

    function testFail_notGetCreatedObject() public {
        vm.startPrank(admin);
        ugcObject.getObject(admin, 3, 1);
        vm.stopPrank();
    }

    function testBurnObject() public {
        vm.startPrank(admin);
        ugcObject.createObject(testTokenUri, 10);
        ugcObject.getObject(admin, 2, 5);
        vm.stopPrank();

        vm.prank(address(ugcCraftLogic));
        ugcObject.burnObject(admin, 2, 2);

        assertEq(ugcObject.balanceOf(admin, 2), 3, "Balance should be 3 after burning");
    }

    function testFailUnauthorizedObjectCreation() public {
        vm.prank(testAddress);
        ugcObject.createObject(testTokenUri, 10);
    }
}
