// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { ERC20 } from "@openzeppelin/token/ERC20/ERC20.sol";

import { console2 } from "forge-std/console2.sol";
import { PRBTest } from "prb-test/PRBTest.sol";
import { StdCheats } from "forge-std/StdCheats.sol";
import { StdUtils } from "forge-std/StdUtils.sol";

import "../src/utils/test/Test_ERC721.sol";
import "../src/object/MaterialObject.sol";
import "../src/object/CraftableObject.sol";
import "../src/object/UGCCraftableObject.sol";
import "../src/CraftLogic.sol";
import "../src/UGCCraftLogic.sol";
import "../src/UGCCraftableObjectFactory.sol";

contract UGCCraftLogicTest is PRBTest, StdCheats, StdUtils {
    MaterialObject materialObject;
    CraftableObject craftObject;
    UGCCraftableObject ugcObject;

    CraftLogic craftLogic;
    UGCCraftLogic ugcCraftLogic;

    UGCCraftableObjectFactory factoryContract;

    ERC20 internal token20;
    Test_ERC721 internal token721;

    address admin = vm.addr(1);
    address tempPhiMap = address(0x123);
    address tempForwarder = address(0xd8253782c45a12053594b9deB72d8e8aB2Fca54c);
    address tempGelatoRelay = 0xd8253782c45a12053594b9deB72d8e8aB2Fca54c;
    address payable tempTreasury = payable(address(0xb7Caa0ed757bbFaA208342752C9B1c541e36a4b9));
    address tempCraftLogic = 0x1234567890123456789012345678901234567890;
    address testAddress = address(0x5037e7747fAa78fc0ECF8DFC526DcD19f73076ce);
    string testTokenUri = "testURI";

    function setUp() public {
        vm.startPrank(admin);
        token20 = new ERC20("Test20", "TST");
        token721 = new Test_ERC721();
        token721.safeMint(admin, 1, "");

        craftLogic = new CraftLogic(tempTreasury, tempGelatoRelay);
        ugcCraftLogic = new UGCCraftLogic(tempForwarder, tempGelatoRelay);

        materialObject = new MaterialObject(tempTreasury, tempPhiMap, tempCraftLogic, address(ugcCraftLogic));
        materialObject.createObject(
            100_001, "DOYHTf8ommXdN7ls6ZubQZvxvBstgdWkPGBm081urvs", BaseObject.Size({ x: 1, y: 1, z: 1 }), tempTreasury
        );
        materialObject.createObject(
            100_002, "5MpxibX_rs6_1-iHOVqlqombCaSVm9PlKHeVbJAwFjA", BaseObject.Size({ x: 1, y: 1, z: 1 }), tempTreasury
        );
        materialObject.createObject(
            100_003, "E2TH6htSdMtKIwdWWPCYCeTxRHoHxDzzK0wyADiFnL8", BaseObject.Size({ x: 1, y: 1, z: 1 }), tempTreasury
        );
        materialObject.createObject(
            100_004, "s1yM1Ar2Y6pH-62G6YRu-6ZMbAeHdJb5HCyfI4KeiQ8", BaseObject.Size({ x: 1, y: 1, z: 1 }), tempTreasury
        );
        materialObject.createObject(
            100_005, "gKRu-iZvr9NPBMUJ3Fs-hcjc7vmCvwT_i9miOAbjZwA", BaseObject.Size({ x: 1, y: 1, z: 1 }), tempTreasury
        );
        materialObject.createObject(
            100_006, "h13ep5-dxry0YmMz3rEDzqOGznzJVZabrcnQPDvLUCQ", BaseObject.Size({ x: 1, y: 1, z: 1 }), tempTreasury
        );
        materialObject.createObject(
            100_007, "xfmu2LHmGNeliEfsg115wuxV83oPzCPzjyD1kqjwC1o", BaseObject.Size({ x: 1, y: 1, z: 1 }), tempTreasury
        );

        factoryContract = new UGCCraftableObjectFactory(address(craftLogic),address(ugcCraftLogic));
        ugcObject = UGCCraftableObjectFactory(factoryContract).createUGCCraftableObject("test", "ZaK");
        ugcObject.createObject(testTokenUri, 10);
        ugcObject.createObject(testTokenUri, 10);
        ugcObject.setApprovalForUGCCrafting(1, 1, true);
        ugcObject.setApprovalForUGCCrafting(2, 1, true);

        craftObject = new CraftableObject(tempTreasury, tempPhiMap, tempCraftLogic,address(ugcCraftLogic));
        craftObject.createObject(
            100_001,
            "DOYHTf8ommXdN7ls6ZubQZvxvBstgdWkPGBm081urvs",
            BaseObject.Size({ x: 1, y: 1, z: 1 }),
            tempTreasury,
            10
        );
        craftObject.createObject(
            100_002,
            "DOYHTf8ommXdN7ls6ZubQZvxvBstgdWkPGBm081urvs",
            BaseObject.Size({ x: 1, y: 1, z: 1 }),
            tempTreasury,
            10
        );

        factoryContract = new UGCCraftableObjectFactory(address(craftLogic),address(ugcCraftLogic));
        ugcObject = UGCCraftableObjectFactory(factoryContract).createUGCCraftableObject("test", "ZaK");
        ugcObject.createObject(testTokenUri, 10); // 1: Cubo
        ugcObject.createObject(testTokenUri, 20); // 2: Rosie
        ugcObject.createObject(testTokenUri, 50); // 3: Maxie
        ugcObject.createObject(testTokenUri, 100); // 4: Jester
        ugcObject.createObject(testTokenUri, 1); // 5: Cuboxie

        ugcCraftLogic.setUgcFactory(address(factoryContract));
        ugcCraftLogic.addToWhitelist(address(materialObject));
        ugcCraftLogic.addToWhitelist(address(craftObject));

        vm.stopPrank();
    }

    function test_createRecipe() public {
        vm.startPrank(admin);

        BaseCraftLogic.Material[] memory materials = new BaseCraftLogic.Material[](1);
        materials[0] = BaseCraftLogic.Material({ tokenAddress: address(materialObject), tokenId: 100_001, amount: 1 });

        BaseCraftLogic.Artifacts[] memory artifacts = new BaseCraftLogic.Artifacts[](1);
        artifacts[0] = BaseCraftLogic.Artifacts({ tokenAddress: address(ugcObject), tokenId: 100_002, amount: 1 });

        // Define catalyst as null
        BaseCraftLogic.Catalyst memory catalyst = BaseCraftLogic.Catalyst({
            tokenAddress: address(0),
            tokenId: 0,
            amount: 0,
            tokenType: BaseCraftLogic.TokenType.ERC20
        });
        ugcCraftLogic.createRecipe(materials, artifacts, catalyst);

        BaseCraftLogic.Recipe memory recipe = ugcCraftLogic.getRecipe(1);
        assertTrue(recipe.active, "Recipe should be active.");
        assertEq(recipe.id, 1, "Recipe ID should be 1.");
        assertEq(recipe.materials[0].tokenId, 100_001, "Recipe toknenid should be 100001.");
        assertEq(recipe.artifacts[0].tokenAddress, address(ugcObject), "Recipe tokenAddress should be ugcObject.");

        vm.stopPrank();
    }

    function test_craft() public {
        vm.startPrank(admin);

        materialObject.getObject(testAddress, 100_001, 1);

        BaseCraftLogic.Material[] memory materials = new BaseCraftLogic.Material[](1);
        materials[0] = BaseCraftLogic.Material({ tokenAddress: address(materialObject), tokenId: 100_001, amount: 1 });

        BaseCraftLogic.Artifacts[] memory artifacts = new BaseCraftLogic.Artifacts[](1);
        artifacts[0] = BaseCraftLogic.Artifacts({ tokenAddress: address(ugcObject), tokenId: 2, amount: 1 });

        // Define catalyst as null
        BaseCraftLogic.Catalyst memory catalyst = BaseCraftLogic.Catalyst({
            tokenAddress: address(0),
            tokenId: 0,
            amount: 0,
            tokenType: BaseCraftLogic.TokenType.ERC20
        });

        ugcCraftLogic.createRecipe(materials, artifacts, catalyst);
        ugcObject.setApprovalForUGCCrafting(2, 1, true); // Approve recipeid 1 for Object(tokenId 2)
        vm.stopPrank();

        vm.prank(testAddress);
        ugcCraftLogic.craft(1);

        BaseCraftLogic.Recipe memory recipe = ugcCraftLogic.getRecipe(1);
        assertEq(recipe.id, 1, "Recipe id should be 1.");

        uint256 balance = ugcObject.balanceOf(testAddress, 2);
        assertEq(balance, 1, "Admin should have 1 ugc Object.");
    }

    function testFail_craftwithNotApprovedCraftableObjectToken() public {
        vm.startPrank(admin);

        materialObject.getObject(testAddress, 100_001, 1);

        BaseCraftLogic.Material[] memory materials = new BaseCraftLogic.Material[](1);
        materials[0] = BaseCraftLogic.Material({ tokenAddress: address(materialObject), tokenId: 100_001, amount: 1 });

        BaseCraftLogic.Artifacts[] memory artifacts = new BaseCraftLogic.Artifacts[](1);
        artifacts[0] = BaseCraftLogic.Artifacts({ tokenAddress: address(ugcObject), tokenId: 2, amount: 1 });

        // Define catalyst as null
        BaseCraftLogic.Catalyst memory catalyst = BaseCraftLogic.Catalyst({
            tokenAddress: address(0),
            tokenId: 0,
            amount: 0,
            tokenType: BaseCraftLogic.TokenType.ERC20
        });

        ugcCraftLogic.createRecipe(materials, artifacts, catalyst);
        ugcObject.setApprovalForUGCCrafting(2, 1, false);
        vm.stopPrank();

        vm.prank(testAddress);
        ugcCraftLogic.craft(1);

        uint256 balance = craftObject.balanceOf(testAddress, 100_002);
        assertEq(balance, 1, "Admin should have 1 Craft Object.");
    }

    function test_craftERC20Catalyst() public {
        vm.startPrank(admin);

        materialObject.getObject(testAddress, 100_001, 1);

        BaseCraftLogic.Material[] memory materials = new BaseCraftLogic.Material[](1);
        materials[0] = BaseCraftLogic.Material({ tokenAddress: address(materialObject), tokenId: 100_001, amount: 1 });

        BaseCraftLogic.Artifacts[] memory artifacts = new BaseCraftLogic.Artifacts[](1);
        artifacts[0] = BaseCraftLogic.Artifacts({ tokenAddress: address(ugcObject), tokenId: 2, amount: 1 });

        // Define catalyst as null
        BaseCraftLogic.Catalyst memory catalyst = BaseCraftLogic.Catalyst({
            tokenAddress: address(token20),
            tokenId: 0,
            amount: 1000,
            tokenType: BaseCraftLogic.TokenType.ERC20
        });

        ugcCraftLogic.createRecipe(materials, artifacts, catalyst);
        ugcObject.setApprovalForUGCCrafting(2, 1, true); // Approve recipeid 1 for Object(tokenId 2)
        // token, account, amount, adjust total supply
        deal(address(token20), testAddress, 1000, true);

        vm.stopPrank();

        vm.prank(testAddress);
        ugcCraftLogic.craft(1);

        uint256 balance = ugcObject.balanceOf(testAddress, 2);
        assertEq(balance, 1, "Admin should have 1 ugc Object.");

        uint256 afBalance = token20.balanceOf(testAddress);
        assertEq(afBalance, 1000, "testAddress should have 1000 token.");
    }

    function testFail_craftERC20Catalyst() public {
        vm.startPrank(admin);

        materialObject.getObject(testAddress, 100_001, 1);

        BaseCraftLogic.Material[] memory materials = new BaseCraftLogic.Material[](1);
        materials[0] = BaseCraftLogic.Material({ tokenAddress: address(materialObject), tokenId: 100_001, amount: 1 });

        BaseCraftLogic.Artifacts[] memory artifacts = new BaseCraftLogic.Artifacts[](1);
        artifacts[0] = BaseCraftLogic.Artifacts({ tokenAddress: address(ugcObject), tokenId: 2, amount: 1 });

        // Define catalyst as null
        BaseCraftLogic.Catalyst memory catalyst = BaseCraftLogic.Catalyst({
            tokenAddress: address(token20),
            tokenId: 0,
            amount: 10_000,
            tokenType: BaseCraftLogic.TokenType.ERC20
        });

        ugcCraftLogic.createRecipe(materials, artifacts, catalyst);
        ugcObject.setApprovalForUGCCrafting(2, 1, true); // Approve recipeid 1 for Object(tokenId 2)
        vm.stopPrank();

        vm.prank(testAddress);
        ugcCraftLogic.craft(1);
    }

    function test_craftERC721Catalyst() public {
        vm.startPrank(admin);

        materialObject.getObject(testAddress, 100_001, 1);

        BaseCraftLogic.Material[] memory materials = new BaseCraftLogic.Material[](1);
        materials[0] = BaseCraftLogic.Material({ tokenAddress: address(materialObject), tokenId: 100_001, amount: 1 });

        BaseCraftLogic.Artifacts[] memory artifacts = new BaseCraftLogic.Artifacts[](1);
        artifacts[0] = BaseCraftLogic.Artifacts({ tokenAddress: address(ugcObject), tokenId: 2, amount: 1 });

        // Define catalyst as null
        BaseCraftLogic.Catalyst memory catalyst = BaseCraftLogic.Catalyst({
            tokenAddress: address(token721),
            tokenId: 1,
            amount: 1,
            tokenType: BaseCraftLogic.TokenType.ERC721
        });

        ugcCraftLogic.createRecipe(materials, artifacts, catalyst);
        ugcObject.setApprovalForUGCCrafting(2, 1, true); // Approve recipeid 1 for Object(tokenId 2)

        // token, account, amount, adjust total supply
        dealERC721(address(token721), testAddress, 1);

        vm.stopPrank();

        vm.prank(testAddress);
        ugcCraftLogic.craft(1);

        uint256 balance = ugcObject.balanceOf(testAddress, 2);
        assertEq(balance, 1, "Admin should have 1 UGC Object.");

        uint256 afBalance = token721.balanceOf(testAddress);
        assertEq(afBalance, 1, "testAddress should have 1 token.");
    }

    function test_craftERC1155Catalyst() public {
        vm.startPrank(admin);

        materialObject.getObject(testAddress, 100_001, 1);

        BaseCraftLogic.Material[] memory materials = new BaseCraftLogic.Material[](1);
        materials[0] = BaseCraftLogic.Material({ tokenAddress: address(materialObject), tokenId: 100_001, amount: 1 });

        BaseCraftLogic.Artifacts[] memory artifacts = new BaseCraftLogic.Artifacts[](1);
        artifacts[0] = BaseCraftLogic.Artifacts({ tokenAddress: address(ugcObject), tokenId: 2, amount: 1 });

        // Define catalyst as null
        BaseCraftLogic.Catalyst memory catalyst = BaseCraftLogic.Catalyst({
            tokenAddress: address(materialObject),
            tokenId: 100_002,
            amount: 1,
            tokenType: BaseCraftLogic.TokenType.ERC1155
        });

        ugcCraftLogic.createRecipe(materials, artifacts, catalyst);
        ugcObject.setApprovalForUGCCrafting(2, 1, true); // Approve recipeid 1 for Object(tokenId 2)

        // token, account, amount, adjust total supply
        dealERC1155(address(materialObject), testAddress, 100_002, 1, true);

        vm.stopPrank();

        vm.prank(testAddress);
        ugcCraftLogic.craft(1);

        uint256 balance = ugcObject.balanceOf(testAddress, 2);
        assertEq(balance, 1, "Admin should have 1 UGC Object.");

        uint256 afBalance = materialObject.balanceOf(testAddress, 100_002);
        assertEq(afBalance, 1, "testAddress should have 1 token.");
    }

    function testFail_notOpenCraft() public {
        vm.startPrank(admin);

        materialObject.getObject(testAddress, 100_001, 1);

        BaseCraftLogic.Material[] memory materials = new BaseCraftLogic.Material[](1);
        materials[0] = BaseCraftLogic.Material({ tokenAddress: address(materialObject), tokenId: 100_001, amount: 1 });

        BaseCraftLogic.Artifacts[] memory artifacts = new BaseCraftLogic.Artifacts[](1);
        artifacts[0] = BaseCraftLogic.Artifacts({ tokenAddress: address(ugcObject), tokenId: 2, amount: 1 });

        // Define catalyst as null
        BaseCraftLogic.Catalyst memory catalyst = BaseCraftLogic.Catalyst({
            tokenAddress: address(0),
            tokenId: 0,
            amount: 0,
            tokenType: BaseCraftLogic.TokenType.ERC20
        });
        ugcCraftLogic.createRecipe(materials, artifacts, catalyst);
        ugcObject.setApprovalForUGCCrafting(2, 1, true); // Approve recipeid 1 for Object(tokenId 2)
        ugcCraftLogic.changeRecipeStatus(1, false);
        vm.stopPrank();

        vm.prank(testAddress);
        ugcCraftLogic.craft(1);
    }

    function testFail_craftNoExistRecipe() public {
        vm.startPrank(admin);
        ugcCraftLogic.craft(1);
    }

    function testFail_updateRecipe_NonExistentID() public {
        vm.startPrank(admin);

        BaseCraftLogic.Material[] memory materials = new BaseCraftLogic.Material[](1);
        materials[0] = BaseCraftLogic.Material({ tokenAddress: address(materialObject), tokenId: 100_001, amount: 1 });

        BaseCraftLogic.Artifacts[] memory artifacts = new BaseCraftLogic.Artifacts[](1);
        artifacts[0] = BaseCraftLogic.Artifacts({ tokenAddress: address(ugcObject), tokenId: 2, amount: 1 });

        // Define catalyst as null
        BaseCraftLogic.Catalyst memory catalyst = BaseCraftLogic.Catalyst({
            tokenAddress: address(0),
            tokenId: 0,
            amount: 0,
            tokenType: BaseCraftLogic.TokenType.ERC20
        });
        // Try to update a recipe that does not exist
        ugcCraftLogic.updateRecipe(2, materials, artifacts, catalyst, true);
    }

    function testFail_craft_InactiveRecipe() public {
        vm.startPrank(admin);

        BaseCraftLogic.Material[] memory materials = new BaseCraftLogic.Material[](1);
        materials[0] = BaseCraftLogic.Material({ tokenAddress: address(materialObject), tokenId: 100_001, amount: 1 });

        BaseCraftLogic.Artifacts[] memory artifacts = new BaseCraftLogic.Artifacts[](1);
        artifacts[0] = BaseCraftLogic.Artifacts({ tokenAddress: address(ugcObject), tokenId: 2, amount: 1 });

        // Define catalyst as null
        BaseCraftLogic.Catalyst memory catalyst = BaseCraftLogic.Catalyst({
            tokenAddress: address(0),
            tokenId: 0,
            amount: 0,
            tokenType: BaseCraftLogic.TokenType.ERC20
        });

        ugcCraftLogic.createRecipe(materials, artifacts, catalyst);
        ugcObject.setApprovalForUGCCrafting(2, 1, true); // Approve recipeid 1 for Object(tokenId 2)
        // Deactivate the recipe
        ugcCraftLogic.updateRecipe(1, materials, artifacts, catalyst, false);
        vm.stopPrank();

        vm.prank(testAddress);
        ugcCraftLogic.craft(1);
    }

    function test_getRecipe() public {
        vm.startPrank(admin);

        BaseCraftLogic.Material[] memory materials = new BaseCraftLogic.Material[](1);
        materials[0] = BaseCraftLogic.Material({ tokenAddress: address(materialObject), tokenId: 100_001, amount: 1 });

        BaseCraftLogic.Artifacts[] memory artifacts = new BaseCraftLogic.Artifacts[](1);
        artifacts[0] = BaseCraftLogic.Artifacts({ tokenAddress: address(ugcObject), tokenId: 2, amount: 1 });

        // Define catalyst as null
        BaseCraftLogic.Catalyst memory catalyst = BaseCraftLogic.Catalyst({
            tokenAddress: address(0),
            tokenId: 0,
            amount: 0,
            tokenType: BaseCraftLogic.TokenType.ERC20
        });

        ugcCraftLogic.createRecipe(materials, artifacts, catalyst);
        ugcObject.setApprovalForUGCCrafting(2, 1, true); // Approve recipeid 1 for Object(tokenId 2)
        BaseCraftLogic.Recipe memory retrievedRecipe = ugcCraftLogic.getRecipe(1);

        assertEq(retrievedRecipe.id, 1, "Recipe ID should be 1.");
        assertEq(retrievedRecipe.active, true, "Recipe should be active.");
        assertEq(retrievedRecipe.materials.length, 1, "Recipe should have 1 material.");
        assertEq(retrievedRecipe.artifacts.length, 1, "Recipe should have 1 artifact.");

        vm.stopPrank();
    }

    function test_updateRecipe() public {
        vm.startPrank(admin);

        BaseCraftLogic.Material[] memory materials = new BaseCraftLogic.Material[](1);
        materials[0] = BaseCraftLogic.Material({ tokenAddress: address(materialObject), tokenId: 100_001, amount: 1 });

        BaseCraftLogic.Artifacts[] memory artifacts = new BaseCraftLogic.Artifacts[](1);
        artifacts[0] = BaseCraftLogic.Artifacts({ tokenAddress: address(ugcObject), tokenId: 2, amount: 1 });

        // Define catalyst as null
        BaseCraftLogic.Catalyst memory catalyst = BaseCraftLogic.Catalyst({
            tokenAddress: address(0),
            tokenId: 0,
            amount: 0,
            tokenType: BaseCraftLogic.TokenType.ERC20
        });

        ugcCraftLogic.createRecipe(materials, artifacts, catalyst);
        ugcObject.setApprovalForUGCCrafting(2, 1, true); // Approve recipeid 1 for Object(tokenId 2)

        BaseCraftLogic.Material[] memory newMaterials = new BaseCraftLogic.Material[](1);
        newMaterials[0] =
            BaseCraftLogic.Material({ tokenAddress: address(materialObject), tokenId: 100_002, amount: 2 });

        BaseCraftLogic.Artifacts[] memory newArtifacts = new BaseCraftLogic.Artifacts[](1);
        newArtifacts[0] = BaseCraftLogic.Artifacts({ tokenAddress: address(ugcObject), tokenId: 100_003, amount: 2 });

        ugcCraftLogic.updateRecipe(1, newMaterials, newArtifacts, catalyst, false);

        BaseCraftLogic.Recipe memory updatedRecipe = ugcCraftLogic.getRecipe(1);

        assertEq(updatedRecipe.id, 1, "Recipe ID should be 1.");
        assertEq(updatedRecipe.active, false, "Recipe should be inactive.");
        assertEq(updatedRecipe.materials.length, 1, "Recipe should have 1 material.");
        assertEq(updatedRecipe.artifacts.length, 1, "Recipe should have 1 artifact.");
        assertEq(updatedRecipe.materials[0].amount, 2, "Material amount should be updated.");
        assertEq(updatedRecipe.artifacts[0].amount, 2, "Artifact amount should be updated.");

        vm.stopPrank();
    }

    function test_changeRecipeStatus() public {
        vm.prank(admin);
        materialObject.getObject(testAddress, 100_001, 1);
        vm.startPrank(testAddress);
        BaseCraftLogic.Material[] memory materials = new BaseCraftLogic.Material[](1);
        materials[0] = BaseCraftLogic.Material({ tokenAddress: address(materialObject), tokenId: 100_001, amount: 1 });

        BaseCraftLogic.Artifacts[] memory artifacts = new BaseCraftLogic.Artifacts[](1);
        artifacts[0] = BaseCraftLogic.Artifacts({ tokenAddress: address(ugcObject), tokenId: 2, amount: 1 });

        // Define catalyst as null
        BaseCraftLogic.Catalyst memory catalyst = BaseCraftLogic.Catalyst({
            tokenAddress: address(materialObject),
            tokenId: 2,
            amount: 1,
            tokenType: BaseCraftLogic.TokenType.ERC1155
        });

        ugcCraftLogic.createRecipe(materials, artifacts, catalyst);

        // token, account, amount, adjust total supply
        dealERC1155(address(materialObject), testAddress, 2, 1, true);

        vm.stopPrank();

        vm.prank(testAddress);
        ugcCraftLogic.changeRecipeStatus(1, false);
        BaseCraftLogic.Recipe memory recipe = ugcCraftLogic.getRecipe(1);
        assertEq(recipe.active, false, "Recipe should be false.");
    }

    function testFail_changeRecipeStatus() public {
        vm.startPrank(testAddress);

        materialObject.getObject(testAddress, 100_001, 1);

        BaseCraftLogic.Material[] memory materials = new BaseCraftLogic.Material[](1);
        materials[0] = BaseCraftLogic.Material({ tokenAddress: address(materialObject), tokenId: 100_001, amount: 1 });

        BaseCraftLogic.Artifacts[] memory artifacts = new BaseCraftLogic.Artifacts[](1);
        artifacts[0] = BaseCraftLogic.Artifacts({ tokenAddress: address(ugcObject), tokenId: 2, amount: 1 });

        // Define catalyst as null
        BaseCraftLogic.Catalyst memory catalyst = BaseCraftLogic.Catalyst({
            tokenAddress: address(materialObject),
            tokenId: 100_002,
            amount: 1,
            tokenType: BaseCraftLogic.TokenType.ERC1155
        });

        ugcCraftLogic.createRecipe(materials, artifacts, catalyst);

        // token, account, amount, adjust total supply
        dealERC1155(address(materialObject), testAddress, 100_002, 1, true);

        vm.stopPrank();

        vm.prank(admin);
        ugcCraftLogic.changeRecipeStatus(1, false);
    }

    function test_craftCubo() public {
        vm.startPrank(admin);

        materialObject.getObject(testAddress, 100_001, 10);
        materialObject.getObject(testAddress, 100_007, 1);

        BaseCraftLogic.Material[] memory materials = new BaseCraftLogic.Material[](2);
        materials[0] = BaseCraftLogic.Material({ tokenAddress: address(materialObject), tokenId: 100_001, amount: 10 });
        materials[1] = BaseCraftLogic.Material({ tokenAddress: address(materialObject), tokenId: 100_007, amount: 1 });

        BaseCraftLogic.Artifacts[] memory artifacts = new BaseCraftLogic.Artifacts[](1);
        artifacts[0] = BaseCraftLogic.Artifacts({ tokenAddress: address(ugcObject), tokenId: 1, amount: 1 });

        // Define catalyst as null
        BaseCraftLogic.Catalyst memory catalyst = BaseCraftLogic.Catalyst({
            tokenAddress: address(0),
            tokenId: 0,
            amount: 0,
            tokenType: BaseCraftLogic.TokenType.ERC20
        });

        ugcCraftLogic.createRecipe(materials, artifacts, catalyst);
        ugcObject.setApprovalForUGCCrafting(1, 1, true); // Approve recipeid 1 for Object(tokenId 2)
        vm.stopPrank();

        vm.prank(testAddress);
        ugcCraftLogic.craft(1);

        uint256 balance = ugcObject.balanceOf(testAddress, 1);
        assertEq(balance, 1, "Admin should have 1 UGC Object.");
    }

    function test_craftRosie() public {
        vm.startPrank(admin);

        materialObject.getObject(testAddress, 100_002, 4);
        materialObject.getObject(testAddress, 100_003, 2);
        materialObject.getObject(testAddress, 100_005, 1);
        materialObject.getObject(testAddress, 100_006, 1);

        BaseCraftLogic.Material[] memory materials = new BaseCraftLogic.Material[](4);
        materials[0] = BaseCraftLogic.Material({ tokenAddress: address(materialObject), tokenId: 100_002, amount: 4 });
        materials[1] = BaseCraftLogic.Material({ tokenAddress: address(materialObject), tokenId: 100_003, amount: 2 });
        materials[2] = BaseCraftLogic.Material({ tokenAddress: address(materialObject), tokenId: 100_005, amount: 1 });
        materials[3] = BaseCraftLogic.Material({ tokenAddress: address(materialObject), tokenId: 100_006, amount: 1 });

        BaseCraftLogic.Artifacts[] memory artifacts = new BaseCraftLogic.Artifacts[](1);
        artifacts[0] = BaseCraftLogic.Artifacts({ tokenAddress: address(ugcObject), tokenId: 2, amount: 1 });

        // Define catalyst as null
        BaseCraftLogic.Catalyst memory catalyst = BaseCraftLogic.Catalyst({
            tokenAddress: address(0),
            tokenId: 0,
            amount: 0,
            tokenType: BaseCraftLogic.TokenType.ERC20
        });

        ugcCraftLogic.createRecipe(materials, artifacts, catalyst);
        ugcObject.setApprovalForUGCCrafting(2, 1, true); // Approve recipeid 1 for Object(tokenId 2)
        vm.stopPrank();

        vm.prank(testAddress);
        ugcCraftLogic.craft(1);

        uint256 balance = ugcObject.balanceOf(testAddress, 2);
        assertEq(balance, 1, "Admin should have 1 UGC Object.");
    }

    function test_craftCuboxie() public {
        vm.startPrank(admin);
        /// cubo
        materialObject.getObject(testAddress, 100_001, 10);
        materialObject.getObject(testAddress, 100_007, 1);

        BaseCraftLogic.Material[] memory materials = new BaseCraftLogic.Material[](2);
        materials[0] = BaseCraftLogic.Material({ tokenAddress: address(materialObject), tokenId: 100_001, amount: 10 });
        materials[1] = BaseCraftLogic.Material({ tokenAddress: address(materialObject), tokenId: 100_007, amount: 1 });

        BaseCraftLogic.Artifacts[] memory artifacts = new BaseCraftLogic.Artifacts[](1);
        artifacts[0] = BaseCraftLogic.Artifacts({ tokenAddress: address(ugcObject), tokenId: 1, amount: 1 });
        // Define catalyst as null
        BaseCraftLogic.Catalyst memory catalyst = BaseCraftLogic.Catalyst({
            tokenAddress: address(0),
            tokenId: 0,
            amount: 0,
            tokenType: BaseCraftLogic.TokenType.ERC20
        });

        ugcCraftLogic.createRecipe(materials, artifacts, catalyst);
        ugcObject.setApprovalForUGCCrafting(1, 1, true); // Approve recipeid 1 for Object(tokenId 2)

        vm.stopPrank();

        vm.prank(testAddress);
        ugcCraftLogic.craft(1);

        vm.startPrank(admin);
        // maxie
        materialObject.getObject(testAddress, 100_003, 4);
        materialObject.getObject(testAddress, 100_004, 3);
        materialObject.getObject(testAddress, 100_005, 1);
        materialObject.getObject(testAddress, 100_006, 1);

        BaseCraftLogic.Material[] memory materials2 = new BaseCraftLogic.Material[](4);
        materials2[0] = BaseCraftLogic.Material({ tokenAddress: address(materialObject), tokenId: 100_003, amount: 4 });
        materials2[1] = BaseCraftLogic.Material({ tokenAddress: address(materialObject), tokenId: 100_004, amount: 3 });
        materials2[2] = BaseCraftLogic.Material({ tokenAddress: address(materialObject), tokenId: 100_005, amount: 1 });
        materials2[3] = BaseCraftLogic.Material({ tokenAddress: address(materialObject), tokenId: 100_006, amount: 1 });

        BaseCraftLogic.Artifacts[] memory artifacts2 = new BaseCraftLogic.Artifacts[](1);
        artifacts2[0] = BaseCraftLogic.Artifacts({ tokenAddress: address(ugcObject), tokenId: 3, amount: 1 });

        ugcCraftLogic.createRecipe(materials2, artifacts2, catalyst);
        ugcObject.setApprovalForUGCCrafting(3, 2, true); // Approve recipeid 2 for Object(tokenId 3)
        vm.stopPrank();

        vm.prank(testAddress);
        ugcCraftLogic.craft(2);

        vm.startPrank(admin);
        // Cuboxie
        BaseCraftLogic.Material[] memory materials3 = new BaseCraftLogic.Material[](2);
        materials3[0] = BaseCraftLogic.Material({ tokenAddress: address(ugcObject), tokenId: 1, amount: 1 });
        materials3[1] = BaseCraftLogic.Material({ tokenAddress: address(ugcObject), tokenId: 3, amount: 1 });

        BaseCraftLogic.Artifacts[] memory artifacts3 = new BaseCraftLogic.Artifacts[](1);
        artifacts3[0] = BaseCraftLogic.Artifacts({ tokenAddress: address(ugcObject), tokenId: 5, amount: 1 });

        ugcCraftLogic.createRecipe(materials3, artifacts3, catalyst);
        ugcObject.setApprovalForUGCCrafting(5, 3, true); // Approve recipeid 3 for Object(tokenId 5)
        vm.stopPrank();

        vm.prank(testAddress);
        ugcCraftLogic.craft(3);
        uint256 balance1 = ugcObject.balanceOf(testAddress, 1);
        assertEq(balance1, 0, "Admin should have 0 UGC Object.");

        uint256 balance2 = ugcObject.balanceOf(testAddress, 2);
        assertEq(balance2, 0, "Admin should have 0 UGC Object.");

        uint256 balance3 = ugcObject.balanceOf(testAddress, 5);
        assertEq(balance3, 1, "Admin should have 1 UGC Object.");
    }
}
