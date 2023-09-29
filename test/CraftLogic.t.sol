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

contract CraftLogicTest is PRBTest, StdCheats, StdUtils {
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
    address tempUGCCraftLogic = 0x1234567890123456789012345678901234567890;
    address testAddress = address(0x5037e7747fAa78fc0ECF8DFC526DcD19f73076ce);

    function setUp() public {
        vm.startPrank(admin);
        token20 = new ERC20("Test20", "TST");
        token721 = new Test_ERC721();
        token721.safeMint(admin, 1, "");

        craftLogic = new CraftLogic(tempForwarder, tempGelatoRelay);
        ugcCraftLogic = new UGCCraftLogic(tempForwarder, tempGelatoRelay);
        materialObject = new MaterialObject(tempTreasury, tempPhiMap, address(craftLogic), tempUGCCraftLogic);
        materialObject.createObject(
            100_001, "DOYHTf8ommXdN7ls6ZubQZvxvBstgdWkPGBm081urvs", BaseObject.Size({ x: 1, y: 1, z: 1 }), tempTreasury
        );
        materialObject.createObject(
            100_002, "DOYHTf8ommXdN7ls6ZubQZvxvBstgdWkPGBm081urvs", BaseObject.Size({ x: 1, y: 1, z: 1 }), tempTreasury
        );
        craftObject = new CraftableObject(tempTreasury, tempPhiMap, address(craftLogic),tempUGCCraftLogic);
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
            9
        );
        craftObject.createObject(
            100_003,
            "DOYHTf8ommXdN7ls6ZubQZvxvBstgdWkPGBm081urvs",
            BaseObject.Size({ x: 1, y: 1, z: 1 }),
            tempTreasury,
            9
        );

        factoryContract = new UGCCraftableObjectFactory(address(craftLogic),address(ugcCraftLogic));
        ugcObject = factoryContract.createUGCCraftableObject("test", "ZaK");

        craftLogic.setUgcFactory(address(factoryContract));
        craftLogic.addToWhitelist(address(materialObject));
        craftLogic.addToWhitelist(address(craftObject));
        vm.stopPrank();
    }

    function test_createRecipe() public {
        vm.startPrank(admin);

        BaseCraftLogic.Material[] memory materials = new BaseCraftLogic.Material[](1);
        materials[0] = BaseCraftLogic.Material({ tokenAddress: address(materialObject), tokenId: 100_001, amount: 1 });

        BaseCraftLogic.Artifacts[] memory artifacts = new BaseCraftLogic.Artifacts[](1);
        artifacts[0] = BaseCraftLogic.Artifacts({ tokenAddress: address(craftObject), tokenId: 100_002, amount: 1 });

        // Define catalyst as null
        BaseCraftLogic.Catalyst memory catalyst = BaseCraftLogic.Catalyst({
            tokenAddress: address(0),
            tokenId: 0,
            amount: 0,
            tokenType: BaseCraftLogic.TokenType.ERC20
        });
        craftLogic.createRecipe(materials, artifacts, catalyst);

        CraftLogic.Recipe memory recipe = craftLogic.getRecipe(1);
        assertTrue(recipe.active, "Recipe should be active.");
        assertEq(recipe.id, 1, "Recipe ID should be 1.");
        assertEq(recipe.materials[0].tokenId, 100_001, "Recipe toknenid should be 100001.");
        assertEq(recipe.artifacts[0].tokenAddress, address(craftObject), "Recipe tokenAddress should be craftObject.");

        vm.stopPrank();
    }

    function testFail_createRecipe_notAContract() public {
        vm.startPrank(admin);

        BaseCraftLogic.Material[] memory materials = new BaseCraftLogic.Material[](1);
        materials[0] = BaseCraftLogic.Material({ tokenAddress: testAddress, tokenId: 100_001, amount: 1 });

        BaseCraftLogic.Artifacts[] memory artifacts = new BaseCraftLogic.Artifacts[](1);
        artifacts[0] = BaseCraftLogic.Artifacts({ tokenAddress: address(craftObject), tokenId: 100_002, amount: 1 });

        // Define catalyst as null
        BaseCraftLogic.Catalyst memory catalyst = BaseCraftLogic.Catalyst({
            tokenAddress: address(0),
            tokenId: 0,
            amount: 0,
            tokenType: BaseCraftLogic.TokenType.ERC20
        });
        vm.expectRevert("MustBeAContract()");
        craftLogic.createRecipe(materials, artifacts, catalyst);
    }

    function test_craft() public {
        vm.startPrank(admin);

        materialObject.getObject(testAddress, 100_001, 1);

        BaseCraftLogic.Material[] memory materials = new BaseCraftLogic.Material[](1);
        materials[0] = BaseCraftLogic.Material({ tokenAddress: address(materialObject), tokenId: 100_001, amount: 1 });

        BaseCraftLogic.Artifacts[] memory artifacts = new BaseCraftLogic.Artifacts[](1);
        artifacts[0] = BaseCraftLogic.Artifacts({ tokenAddress: address(craftObject), tokenId: 100_002, amount: 1 });

        // Define catalyst as null
        BaseCraftLogic.Catalyst memory catalyst = BaseCraftLogic.Catalyst({
            tokenAddress: address(0),
            tokenId: 0,
            amount: 0,
            tokenType: BaseCraftLogic.TokenType.ERC20
        });

        craftLogic.createRecipe(materials, artifacts, catalyst);
        vm.stopPrank();

        vm.prank(testAddress);
        craftLogic.craft(1);

        uint256 balance = craftObject.balanceOf(testAddress, 100_002);
        assertEq(balance, 1, "Admin should have 1 Craft Object.");
        assertEq(craftObject.totalSupply(100_002), 1, "supply should be 1");
    }

    function test_craftMaxSupplyArtifacts() public {
        vm.startPrank(admin);

        materialObject.getObject(testAddress, 100_001, 3);
        assertEq(materialObject.balanceOf(testAddress, 100_001), 3, "Balance should be 3");
        BaseCraftLogic.Material[] memory materials = new BaseCraftLogic.Material[](1);
        materials[0] = BaseCraftLogic.Material({ tokenAddress: address(materialObject), tokenId: 100_001, amount: 1 });

        BaseCraftLogic.Artifacts[] memory artifacts = new BaseCraftLogic.Artifacts[](1);
        artifacts[0] = BaseCraftLogic.Artifacts({ tokenAddress: address(craftObject), tokenId: 100_002, amount: 3 });

        // Define catalyst as null
        BaseCraftLogic.Catalyst memory catalyst = BaseCraftLogic.Catalyst({
            tokenAddress: address(0),
            tokenId: 0,
            amount: 0,
            tokenType: BaseCraftLogic.TokenType.ERC20
        });

        craftLogic.createRecipe(materials, artifacts, catalyst);
        vm.stopPrank();

        vm.prank(testAddress);
        craftLogic.craft(1);
        assertEq(materialObject.balanceOf(testAddress, 100_001), 2, "Balance should be 2");
        assertEq(craftObject.getMaxClaimed(100_002), 9, "supply should be 9");
        assertEq(craftObject.balanceOf(testAddress, 100_002), 3, "Balance should be 3");
        assertEq(craftObject.totalSupply(100_002), 3, "supply should be 3");

        vm.prank(testAddress);
        craftLogic.craft(1);
        assertEq(craftObject.balanceOf(testAddress, 100_002), 6, "Balance should be 6");
        assertEq(craftObject.totalSupply(100_002), 6, "supply should be 6");

        vm.prank(testAddress);
        craftLogic.craft(1);
        assertEq(craftObject.balanceOf(testAddress, 100_002), 9, "Balance should be 9");
        assertEq(craftObject.totalSupply(100_002), 9, "supply should be 9");
    }

    function testFail_craftOverMaxSupplyArtifacts() public {
        vm.startPrank(admin);

        materialObject.getObject(testAddress, 100_001, 4);
        assertEq(materialObject.balanceOf(testAddress, 100_001), 4, "Balance should be 3");
        BaseCraftLogic.Material[] memory materials = new BaseCraftLogic.Material[](1);
        materials[0] = BaseCraftLogic.Material({ tokenAddress: address(materialObject), tokenId: 100_001, amount: 1 });

        BaseCraftLogic.Artifacts[] memory artifacts = new BaseCraftLogic.Artifacts[](1);
        artifacts[0] = BaseCraftLogic.Artifacts({ tokenAddress: address(craftObject), tokenId: 100_002, amount: 5 });

        // Define catalyst as null
        BaseCraftLogic.Catalyst memory catalyst = BaseCraftLogic.Catalyst({
            tokenAddress: address(0),
            tokenId: 0,
            amount: 0,
            tokenType: BaseCraftLogic.TokenType.ERC20
        });

        craftLogic.createRecipe(materials, artifacts, catalyst);
        vm.stopPrank();

        vm.prank(testAddress);
        craftLogic.craft(1);
        assertEq(craftObject.getMaxClaimed(100_002), 9, "supply should be 9");
        assertEq(craftObject.balanceOf(testAddress, 100_002), 5, "Balance should be 5");
        assertEq(craftObject.totalSupply(100_002), 5, "supply should be 5");

        vm.prank(testAddress);
        craftLogic.craft(1);
    }

    function test_craftERC20Catalyst() public {
        vm.startPrank(admin);

        materialObject.getObject(testAddress, 100_001, 1);

        BaseCraftLogic.Material[] memory materials = new BaseCraftLogic.Material[](1);
        materials[0] = BaseCraftLogic.Material({ tokenAddress: address(materialObject), tokenId: 100_001, amount: 1 });

        BaseCraftLogic.Artifacts[] memory artifacts = new BaseCraftLogic.Artifacts[](1);
        artifacts[0] = BaseCraftLogic.Artifacts({ tokenAddress: address(craftObject), tokenId: 100_002, amount: 1 });

        // Define catalyst as null
        BaseCraftLogic.Catalyst memory catalyst = BaseCraftLogic.Catalyst({
            tokenAddress: address(token20),
            tokenId: 0,
            amount: 1000,
            tokenType: BaseCraftLogic.TokenType.ERC20
        });

        craftLogic.createRecipe(materials, artifacts, catalyst);

        // token, account, amount, adjust total supply
        deal(address(token20), testAddress, 1000, true);

        vm.stopPrank();

        vm.prank(testAddress);
        craftLogic.craft(1);

        uint256 balance = craftObject.balanceOf(testAddress, 100_002);
        assertEq(balance, 1, "Admin should have 1 Craft Object.");

        uint256 afBalance = token20.balanceOf(testAddress);
        assertEq(afBalance, 1000, "testAddress should have 1000 token.");
    }

    function testFail_craftERC20Catalyst() public {
        vm.startPrank(admin);

        materialObject.getObject(testAddress, 100_001, 1);

        BaseCraftLogic.Material[] memory materials = new BaseCraftLogic.Material[](1);
        materials[0] = BaseCraftLogic.Material({ tokenAddress: address(materialObject), tokenId: 100_001, amount: 1 });

        BaseCraftLogic.Artifacts[] memory artifacts = new BaseCraftLogic.Artifacts[](1);
        artifacts[0] = BaseCraftLogic.Artifacts({ tokenAddress: address(craftObject), tokenId: 100_002, amount: 1 });

        // Define catalyst as null
        BaseCraftLogic.Catalyst memory catalyst = BaseCraftLogic.Catalyst({
            tokenAddress: address(token20),
            tokenId: 0,
            amount: 1000,
            tokenType: BaseCraftLogic.TokenType.ERC20
        });

        craftLogic.createRecipe(materials, artifacts, catalyst);

        vm.stopPrank();

        vm.prank(testAddress);
        craftLogic.craft(1);
    }

    function test_craftERC721Catalyst() public {
        vm.startPrank(admin);

        materialObject.getObject(testAddress, 100_001, 1);

        BaseCraftLogic.Material[] memory materials = new BaseCraftLogic.Material[](1);
        materials[0] = BaseCraftLogic.Material({ tokenAddress: address(materialObject), tokenId: 100_001, amount: 1 });

        BaseCraftLogic.Artifacts[] memory artifacts = new BaseCraftLogic.Artifacts[](1);
        artifacts[0] = BaseCraftLogic.Artifacts({ tokenAddress: address(craftObject), tokenId: 100_002, amount: 1 });

        // Define catalyst as null
        BaseCraftLogic.Catalyst memory catalyst = BaseCraftLogic.Catalyst({
            tokenAddress: address(token721),
            tokenId: 1,
            amount: 1,
            tokenType: BaseCraftLogic.TokenType.ERC721
        });

        craftLogic.createRecipe(materials, artifacts, catalyst);

        // token, account, amount, adjust total supply
        dealERC721(address(token721), testAddress, 1);

        vm.stopPrank();

        vm.prank(testAddress);
        craftLogic.craft(1);

        uint256 balance = craftObject.balanceOf(testAddress, 100_002);
        assertEq(balance, 1, "Admin should have 1 Craft Object.");

        uint256 afBalance = token721.balanceOf(testAddress);
        assertEq(afBalance, 1, "testAddress should have 1 token.");
    }

    function test_craftERC721Catalyst2() public {
        vm.startPrank(admin);

        materialObject.getObject(testAddress, 100_001, 1);

        BaseCraftLogic.Material[] memory materials = new BaseCraftLogic.Material[](1);
        materials[0] = BaseCraftLogic.Material({ tokenAddress: address(materialObject), tokenId: 100_001, amount: 1 });

        BaseCraftLogic.Artifacts[] memory artifacts = new BaseCraftLogic.Artifacts[](1);
        artifacts[0] = BaseCraftLogic.Artifacts({ tokenAddress: address(craftObject), tokenId: 100_002, amount: 1 });

        // Define catalyst as null
        BaseCraftLogic.Catalyst memory catalyst = BaseCraftLogic.Catalyst({
            tokenAddress: address(token721),
            tokenId: 2,
            amount: 1,
            tokenType: BaseCraftLogic.TokenType.ERC721
        });

        craftLogic.createRecipe(materials, artifacts, catalyst);

        // token, account, amount, adjust total supply
        dealERC721(address(token721), testAddress, 1);

        vm.stopPrank();

        vm.prank(testAddress);
        craftLogic.craft(1);

        uint256 balance = craftObject.balanceOf(testAddress, 100_002);
        assertEq(balance, 1, "Admin should have 1 Craft Object.");

        uint256 afBalance = token721.balanceOf(testAddress);
        assertEq(afBalance, 1, "testAddress should have 1 token.");
    }

    function test_craftERC1155Catalyst() public {
        vm.startPrank(admin);

        materialObject.getObject(testAddress, 100_001, 1);

        BaseCraftLogic.Material[] memory materials = new BaseCraftLogic.Material[](1);
        materials[0] = BaseCraftLogic.Material({ tokenAddress: address(materialObject), tokenId: 100_001, amount: 1 });

        BaseCraftLogic.Artifacts[] memory artifacts = new BaseCraftLogic.Artifacts[](1);
        artifacts[0] = BaseCraftLogic.Artifacts({ tokenAddress: address(craftObject), tokenId: 100_002, amount: 1 });

        // Define catalyst as null
        BaseCraftLogic.Catalyst memory catalyst = BaseCraftLogic.Catalyst({
            tokenAddress: address(materialObject),
            tokenId: 100_002,
            amount: 1,
            tokenType: BaseCraftLogic.TokenType.ERC1155
        });

        craftLogic.createRecipe(materials, artifacts, catalyst);

        // token, account, amount, adjust total supply
        dealERC1155(address(materialObject), testAddress, 100_002, 1, true);

        vm.stopPrank();

        vm.prank(testAddress);
        craftLogic.craft(1);
    }

    function testFail_craftERC1155Catalyst() public {
        vm.startPrank(admin);

        materialObject.getObject(testAddress, 100_001, 1);

        BaseCraftLogic.Material[] memory materials = new BaseCraftLogic.Material[](1);
        materials[0] = BaseCraftLogic.Material({ tokenAddress: address(materialObject), tokenId: 100_001, amount: 1 });

        BaseCraftLogic.Artifacts[] memory artifacts = new BaseCraftLogic.Artifacts[](1);
        artifacts[0] = BaseCraftLogic.Artifacts({ tokenAddress: address(craftObject), tokenId: 100_002, amount: 1 });

        // Define catalyst as null
        BaseCraftLogic.Catalyst memory catalyst = BaseCraftLogic.Catalyst({
            tokenAddress: address(materialObject),
            tokenId: 100_002,
            amount: 1,
            tokenType: BaseCraftLogic.TokenType.ERC1155
        });

        craftLogic.createRecipe(materials, artifacts, catalyst);

        vm.stopPrank();

        vm.prank(testAddress);
        craftLogic.craft(1);
    }

    function testFail_notOpenCraft() public {
        vm.startPrank(admin);

        materialObject.getObject(testAddress, 100_001, 1);

        BaseCraftLogic.Material[] memory materials = new BaseCraftLogic.Material[](1);
        materials[0] = BaseCraftLogic.Material({ tokenAddress: address(materialObject), tokenId: 100_001, amount: 1 });

        BaseCraftLogic.Artifacts[] memory artifacts = new BaseCraftLogic.Artifacts[](1);
        artifacts[0] = BaseCraftLogic.Artifacts({ tokenAddress: address(craftObject), tokenId: 100_002, amount: 1 });

        // Define catalyst as null
        BaseCraftLogic.Catalyst memory catalyst = BaseCraftLogic.Catalyst({
            tokenAddress: address(0),
            tokenId: 0,
            amount: 0,
            tokenType: BaseCraftLogic.TokenType.ERC20
        });
        craftLogic.createRecipe(materials, artifacts, catalyst);
        craftLogic.changeRecipeStatus(1, false);
        vm.stopPrank();

        vm.prank(testAddress);
        craftLogic.craft(1);
    }

    function testFail_craftNoExistRecipe() public {
        vm.startPrank(admin);
        craftLogic.craft(1);
    }

    function testFail_updateRecipe_NonExistentID() public {
        vm.startPrank(admin);

        BaseCraftLogic.Material[] memory materials = new BaseCraftLogic.Material[](1);
        materials[0] = BaseCraftLogic.Material({ tokenAddress: address(materialObject), tokenId: 100_001, amount: 1 });

        BaseCraftLogic.Artifacts[] memory artifacts = new BaseCraftLogic.Artifacts[](1);
        artifacts[0] = BaseCraftLogic.Artifacts({ tokenAddress: address(craftObject), tokenId: 100_002, amount: 1 });

        // Define catalyst as null
        BaseCraftLogic.Catalyst memory catalyst = BaseCraftLogic.Catalyst({
            tokenAddress: address(0),
            tokenId: 0,
            amount: 0,
            tokenType: BaseCraftLogic.TokenType.ERC20
        });
        // Try to update a recipe that does not exist
        craftLogic.updateRecipe(2, materials, artifacts, catalyst, true);
    }

    function testFail_craft_InactiveRecipe() public {
        vm.startPrank(admin);

        BaseCraftLogic.Material[] memory materials = new BaseCraftLogic.Material[](1);
        materials[0] = BaseCraftLogic.Material({ tokenAddress: address(materialObject), tokenId: 100_001, amount: 1 });

        BaseCraftLogic.Artifacts[] memory artifacts = new BaseCraftLogic.Artifacts[](1);
        artifacts[0] = BaseCraftLogic.Artifacts({ tokenAddress: address(craftObject), tokenId: 100_002, amount: 1 });

        // Define catalyst as null
        BaseCraftLogic.Catalyst memory catalyst = BaseCraftLogic.Catalyst({
            tokenAddress: address(0),
            tokenId: 0,
            amount: 0,
            tokenType: BaseCraftLogic.TokenType.ERC20
        });

        craftLogic.createRecipe(materials, artifacts, catalyst);
        // Deactivate the recipe
        craftLogic.updateRecipe(1, materials, artifacts, catalyst, false);
        vm.stopPrank();

        vm.prank(testAddress);
        craftLogic.craft(1);
    }

    function test_getRecipe() public {
        vm.startPrank(admin);

        BaseCraftLogic.Material[] memory materials = new BaseCraftLogic.Material[](1);
        materials[0] = BaseCraftLogic.Material({ tokenAddress: address(materialObject), tokenId: 100_001, amount: 1 });

        BaseCraftLogic.Artifacts[] memory artifacts = new BaseCraftLogic.Artifacts[](1);
        artifacts[0] = BaseCraftLogic.Artifacts({ tokenAddress: address(craftObject), tokenId: 100_002, amount: 1 });

        // Define catalyst as null
        BaseCraftLogic.Catalyst memory catalyst = BaseCraftLogic.Catalyst({
            tokenAddress: address(0),
            tokenId: 0,
            amount: 0,
            tokenType: BaseCraftLogic.TokenType.ERC20
        });

        craftLogic.createRecipe(materials, artifacts, catalyst);

        CraftLogic.Recipe memory retrievedRecipe = craftLogic.getRecipe(1);

        assertEq(retrievedRecipe.id, 1, "Recipe ID should be 1.");
        assertEq(retrievedRecipe.active, true, "Recipe should be active.");
        assertEq(retrievedRecipe.materials.length, 1, "Recipe should have 1 material.");
        assertEq(retrievedRecipe.artifacts.length, 1, "Recipe should have 1 artifact.");

        vm.stopPrank();
    }

    function test_initugcObjectCheckUGCAddress() public {
        assertEq(factoryContract.checkUGCAddress(address(ugcObject)), true, "ugcObject true");
    }

    function test_ugcObjectCheckUGCAddress() public {
        vm.startPrank(admin);
        UGCCraftableObject ugcObject2 = factoryContract.createUGCCraftableObject("test2", "ZaK2");
        vm.stopPrank();
        vm.prank(testAddress);
        assertEq(factoryContract.checkUGCAddress(address(ugcObject2)), true, "ugcObjec2 true");
    }

    function test_crafWithCraftableObjectAsMaterial() public {
        vm.startPrank(admin);
        materialObject.getObject(testAddress, 100_001, 1);
        BaseCraftLogic.Catalyst memory catalyst = BaseCraftLogic.Catalyst({
            tokenAddress: address(0),
            tokenId: 0,
            amount: 0,
            tokenType: BaseCraftLogic.TokenType.ERC20
        });

        BaseCraftLogic.Material[] memory materials1 = new BaseCraftLogic.Material[](1);
        materials1[0] = BaseCraftLogic.Material({ tokenAddress: address(materialObject), tokenId: 100_001, amount: 1 });

        BaseCraftLogic.Artifacts[] memory artifacts1 = new BaseCraftLogic.Artifacts[](1);
        artifacts1[0] = BaseCraftLogic.Artifacts({ tokenAddress: address(craftObject), tokenId: 100_002, amount: 1 });

        craftLogic.createRecipe(materials1, artifacts1, catalyst);

        ugcObject.createObject("test", 10);

        BaseCraftLogic.Material[] memory materials2 = new BaseCraftLogic.Material[](1);
        materials2[0] = BaseCraftLogic.Material({ tokenAddress: address(craftObject), tokenId: 100_002, amount: 1 });

        BaseCraftLogic.Artifacts[] memory artifacts2 = new BaseCraftLogic.Artifacts[](2);
        artifacts2[0] = BaseCraftLogic.Artifacts({ tokenAddress: address(craftObject), tokenId: 100_003, amount: 1 });
        artifacts2[1] = BaseCraftLogic.Artifacts({ tokenAddress: address(ugcObject), tokenId: 1, amount: 1 });

        craftLogic.createRecipe(materials2, artifacts2, catalyst);
        ugcObject.setApprovalForCrafting(1, 2, true);

        BaseCraftLogic.Material[] memory materials3 = new BaseCraftLogic.Material[](1);
        materials3[0] = BaseCraftLogic.Material({ tokenAddress: address(ugcObject), tokenId: 1, amount: 1 });

        BaseCraftLogic.Artifacts[] memory artifacts3 = new BaseCraftLogic.Artifacts[](1);
        artifacts3[0] = BaseCraftLogic.Artifacts({ tokenAddress: address(craftObject), tokenId: 100_001, amount: 1 });

        craftLogic.createRecipe(materials3, artifacts3, catalyst);

        vm.stopPrank();

        vm.prank(testAddress);
        craftLogic.craft(1);

        vm.prank(testAddress);
        craftLogic.craft(2);

        uint256 balanceAftercraft1 = ugcObject.balanceOf(testAddress, 1);
        assertEq(balanceAftercraft1, 1, "The balance should be 1");
        uint256 balanceAftercraft2 = craftObject.balanceOf(testAddress, 100_003);
        assertEq(balanceAftercraft2, 1, "The balance should be 1");

        vm.prank(testAddress);
        craftLogic.craft(3);
        uint256 balanceAftercraft3 = craftObject.balanceOf(testAddress, 100_001);
        assertEq(balanceAftercraft3, 1, "The balance should be 0");
    }

    function test_updateRecipe() public {
        vm.startPrank(admin);

        BaseCraftLogic.Material[] memory materials = new BaseCraftLogic.Material[](1);
        materials[0] = BaseCraftLogic.Material({ tokenAddress: address(materialObject), tokenId: 100_001, amount: 1 });

        BaseCraftLogic.Artifacts[] memory artifacts = new BaseCraftLogic.Artifacts[](1);
        artifacts[0] = BaseCraftLogic.Artifacts({ tokenAddress: address(craftObject), tokenId: 100_002, amount: 1 });

        // Define catalyst as null
        BaseCraftLogic.Catalyst memory catalyst = BaseCraftLogic.Catalyst({
            tokenAddress: address(0),
            tokenId: 0,
            amount: 0,
            tokenType: BaseCraftLogic.TokenType.ERC20
        });

        craftLogic.createRecipe(materials, artifacts, catalyst);

        BaseCraftLogic.Material[] memory newMaterials = new BaseCraftLogic.Material[](1);
        newMaterials[0] =
            BaseCraftLogic.Material({ tokenAddress: address(materialObject), tokenId: 100_002, amount: 2 });

        BaseCraftLogic.Artifacts[] memory newArtifacts = new BaseCraftLogic.Artifacts[](1);
        newArtifacts[0] = BaseCraftLogic.Artifacts({ tokenAddress: address(craftObject), tokenId: 100_003, amount: 2 });

        craftLogic.updateRecipe(1, newMaterials, newArtifacts, catalyst, false);

        CraftLogic.Recipe memory updatedRecipe = craftLogic.getRecipe(1);

        assertEq(updatedRecipe.id, 1, "Recipe ID should be 1.");
        assertEq(updatedRecipe.active, false, "Recipe should be inactive.");
        assertEq(updatedRecipe.materials.length, 1, "Recipe should have 1 material.");
        assertEq(updatedRecipe.artifacts.length, 1, "Recipe should have 1 artifact.");
        assertEq(updatedRecipe.materials[0].amount, 2, "Material amount should be updated.");
        assertEq(updatedRecipe.artifacts[0].amount, 2, "Artifact amount should be updated.");

        vm.stopPrank();
    }

    function test_craftAndBurn() public {
        vm.startPrank(admin);

        materialObject.getObject(testAddress, 100_001, 1);

        BaseCraftLogic.Material[] memory materials = new BaseCraftLogic.Material[](1);
        materials[0] = BaseCraftLogic.Material({ tokenAddress: address(materialObject), tokenId: 100_001, amount: 1 });

        BaseCraftLogic.Artifacts[] memory artifacts = new BaseCraftLogic.Artifacts[](1);
        artifacts[0] = BaseCraftLogic.Artifacts({ tokenAddress: address(craftObject), tokenId: 100_002, amount: 1 });

        // Define catalyst as null
        BaseCraftLogic.Catalyst memory catalyst = BaseCraftLogic.Catalyst({
            tokenAddress: address(0),
            tokenId: 0,
            amount: 0,
            tokenType: BaseCraftLogic.TokenType.ERC20
        });

        craftLogic.createRecipe(materials, artifacts, catalyst);
        vm.stopPrank();

        vm.prank(testAddress);
        craftLogic.craft(1);

        uint256 balance = craftObject.balanceOf(testAddress, 100_002);
        assertEq(balance, 1, "testaddress should have 1 Craft Object.");

        vm.prank(address(craftLogic));
        craftObject.burnObject(testAddress, 100_002, 1);
        uint256 balanceAfterburn = craftObject.balanceOf(testAddress, 100_002);
        assertEq(balanceAfterburn, 0, "The balance should be 0");
    }

    function test_changeRecipeStatus() public {
        vm.startPrank(admin);
        materialObject.getObject(testAddress, 100_001, 1);
        BaseCraftLogic.Material[] memory materials = new BaseCraftLogic.Material[](1);
        materials[0] = BaseCraftLogic.Material({ tokenAddress: address(materialObject), tokenId: 100_001, amount: 1 });

        BaseCraftLogic.Artifacts[] memory artifacts = new BaseCraftLogic.Artifacts[](1);
        artifacts[0] = BaseCraftLogic.Artifacts({ tokenAddress: address(craftObject), tokenId: 100_002, amount: 1 });

        // Define catalyst as null
        BaseCraftLogic.Catalyst memory catalyst = BaseCraftLogic.Catalyst({
            tokenAddress: address(materialObject),
            tokenId: 100_002,
            amount: 1,
            tokenType: BaseCraftLogic.TokenType.ERC1155
        });

        craftLogic.createRecipe(materials, artifacts, catalyst);

        // token, account, amount, adjust total supply
        dealERC1155(address(materialObject), testAddress, 100_002, 1, true);
        vm.stopPrank();

        vm.prank(testAddress);
        craftLogic.craft(1);

        vm.startPrank(admin);
        craftLogic.changeRecipeStatus(1, false);
        BaseCraftLogic.Recipe memory recipe = craftLogic.getRecipe(1);
        assertEq(recipe.active, false, "Recipe should be false.");
        vm.stopPrank();
    }

    function testFail_createRecipe() public {
        vm.startPrank(testAddress);

        materialObject.getObject(testAddress, 100_001, 1);

        BaseCraftLogic.Material[] memory materials = new BaseCraftLogic.Material[](1);
        materials[0] = BaseCraftLogic.Material({ tokenAddress: address(materialObject), tokenId: 100_001, amount: 1 });

        BaseCraftLogic.Artifacts[] memory artifacts = new BaseCraftLogic.Artifacts[](1);
        artifacts[0] = BaseCraftLogic.Artifacts({ tokenAddress: address(craftObject), tokenId: 100_002, amount: 1 });

        // Define catalyst as null
        BaseCraftLogic.Catalyst memory catalyst = BaseCraftLogic.Catalyst({
            tokenAddress: address(materialObject),
            tokenId: 100_002,
            amount: 1,
            tokenType: BaseCraftLogic.TokenType.ERC1155
        });

        craftLogic.createRecipe(materials, artifacts, catalyst);
    }

    function testFail_changeRecipeStatus_NonExistentRecipe() public {
        vm.startPrank(admin);

        materialObject.getObject(testAddress, 100_001, 1);

        BaseCraftLogic.Material[] memory materials = new BaseCraftLogic.Material[](1);
        materials[0] = BaseCraftLogic.Material({ tokenAddress: address(materialObject), tokenId: 100_001, amount: 1 });

        BaseCraftLogic.Artifacts[] memory artifacts = new BaseCraftLogic.Artifacts[](1);
        artifacts[0] = BaseCraftLogic.Artifacts({ tokenAddress: address(craftObject), tokenId: 100_002, amount: 1 });

        // Define catalyst as null
        BaseCraftLogic.Catalyst memory catalyst = BaseCraftLogic.Catalyst({
            tokenAddress: address(materialObject),
            tokenId: 100_002,
            amount: 1,
            tokenType: BaseCraftLogic.TokenType.ERC1155
        });

        craftLogic.createRecipe(materials, artifacts, catalyst);

        // token, account, amount, adjust total supply
        dealERC1155(address(materialObject), testAddress, 100_002, 1, true);

        vm.stopPrank();

        vm.prank(testAddress);
        vm.expectRevert(abi.encodeWithSelector(BaseCraftLogic.NonExistentRecipe.selector, 1));
        craftLogic.changeRecipeStatus(1, false);
    }
}
