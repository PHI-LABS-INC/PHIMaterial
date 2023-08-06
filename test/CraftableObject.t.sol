// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { console2 } from "forge-std/console2.sol";
import { PRBTest } from "prb-test/PRBTest.sol";
import { StdCheats } from "forge-std/StdCheats.sol";

import "../src/object/MaterialObject.sol";
import "../src/object/CraftableObject.sol";
import "../src/CraftLogic.sol";

contract CraftableObjectTest is PRBTest, StdCheats {
    MaterialObject materialObject;
    CraftableObject craftObject;
    CraftLogic craftLogic;

    address admin = vm.addr(1);
    address tempPhiMap = address(0x123);
    address tempForwarder = address(0xd8253782c45a12053594b9deB72d8e8aB2Fca54c);
    address tempGelatoRelay = 0xd8253782c45a12053594b9deB72d8e8aB2Fca54c;
    address payable tempTreasury = payable(address(0xb7Caa0ed757bbFaA208342752C9B1c541e36a4b9));
    address tempUGCCraftLogic = 0x1234567890123456789012345678901234567890;
    address testAddress = address(0x5037e7747fAa78fc0ECF8DFC526DcD19f73076ce);

    // Events for tests
    event SetCraftLogic(address oldCraftLogic, address indexed newCraftLogic);

    function setUp() public {
        vm.startPrank(admin);
        craftLogic = new CraftLogic(tempForwarder, tempGelatoRelay);
        materialObject = new MaterialObject(tempTreasury, tempPhiMap, address(craftLogic), tempUGCCraftLogic);
        craftObject = new CraftableObject(tempTreasury, tempPhiMap, address(craftLogic),tempUGCCraftLogic);
        craftObject.createObject(
            100_001,
            "DOYHTf8ommXdN7ls6ZubQZvxvBstgdWkPGBm081urvs",
            BaseObject.Size({ x: 1, y: 1, z: 1 }),
            tempTreasury,
            10
        );
        vm.stopPrank();
    }

    // Test CraftableObject initialization
    function test_initialization() public {
        assertEq("Phi Craft Object", craftObject.name(), "The contract should have the correct name");
        assertEq("Phi-COS", craftObject.symbol(), "The contract should have the correct symbol");
        assertEq(
            "https://www.arweave.net/",
            craftObject.baseMetadataURI(),
            "The contract should have the correct baseMetadataURI"
        );
        assertEq(tempTreasury, craftObject.treasuryAddress(), "The contract should have the correct treasuryAddress");
        assertEq(tempPhiMap, craftObject.phiMapAddress(), "The contract should have the correct phiMapAddress");
        assertEq(1000, craftObject.secondaryRoyalty(), "The contract should have the correct secondaryRoyalty");
    }

    function test_initialOwner() public {
        assertTrue(craftObject.ownerCheck(admin), "The deployer should be an owner");
    }

    function test_setOwner() public {
        address newOwner = address(0x123);
        vm.startPrank(admin);
        craftObject.setOwner(newOwner);
        vm.stopPrank();
        assertTrue(craftObject.ownerCheck(newOwner), "The new owner should be set");
    }

    function test_removeOwner() public {
        address newOwner = address(0x123);
        vm.startPrank(admin);
        craftObject.setOwner(newOwner);
        craftObject.removeOwner(newOwner);
        vm.stopPrank();
        assertFalse(craftObject.ownerCheck(newOwner), "The owner should be removed");
    }

    function testFail_setOwner_notOwner() public {
        address notOwner = address(0x234);
        vm.prank(notOwner);
        vm.expectRevert("MustBeOwner()");
        craftObject.setOwner(notOwner);
    }

    function testFail_removeOwner_notOwner() public {
        address notOwner = address(0x234);
        vm.prank(notOwner);
        vm.expectRevert("MustBeOwner()");
        craftObject.removeOwner(notOwner);
    }

    function test_setCraftLogic() public {
        CraftLogic newCraftLogic = new CraftLogic(tempForwarder, tempGelatoRelay);

        vm.startPrank(admin);
        // Expect the SetCraftLogic event to be emitted
        vm.expectEmit();
        emit SetCraftLogic(craftObject.craftLogic(), address(newCraftLogic));
        craftObject.setCraftLogic(address(newCraftLogic));
        vm.stopPrank();

        assertEq(address(newCraftLogic), craftObject.craftLogic(), "The new CraftLogic should be set");
    }

    function testFail_setCraftLogic_notAContract() public {
        address newCraftLogic = address(0x456);

        vm.prank(admin);
        vm.expectRevert("MustBeAContract()");
        craftObject.setCraftLogic(newCraftLogic);
    }

    function testFail_setCraftLogic_notOwner() public {
        address notOwner = address(0x789);
        address newCraftLogic = address(0x456);
        vm.prank(notOwner);
        vm.expectRevert("MustBeOwner()");
        craftObject.setCraftLogic(newCraftLogic);
    }

    function test_objectCreation() public {
        uint256 newTokenId = 100_002;
        string memory newUri = "F8ommXdN7ls6ZubQZvxvBstgdWkPGBm081urvD0YHT";
        BaseObject.Size memory newSize = BaseObject.Size({ x: 2, y: 2, z: 2 });
        vm.startPrank(admin);
        craftObject.createObject(newTokenId, newUri, newSize, tempTreasury, 10);
        vm.stopPrank();
    }

    function testFail_objectCreation_tokenIdExists() public {
        vm.startPrank(admin);
        materialObject.getObject(testAddress, 100_001, 1);
        BaseCraftLogic.Material[] memory materials = new BaseCraftLogic.Material[](1);
        materials[0] = BaseCraftLogic.Material({ tokenAddress: address(materialObject), tokenId: 100_001, amount: 1 });
        BaseCraftLogic.Artifacts[] memory artifacts = new BaseCraftLogic.Artifacts[](1);
        artifacts[0] = BaseCraftLogic.Artifacts({ tokenAddress: address(craftObject), tokenId: 100_001, amount: 1 });
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
        vm.expectRevert("TokenIdExists()");
        craftLogic.craft(1); //< create Craft Object 100001

        uint256 existingTokenId = 100_001;
        string memory newUri = "F8ommXdN7ls6ZubQZvxvBstgdWkPGBm081urvD0YHT";
        BaseObject.Size memory newSize = BaseObject.Size({ x: 2, y: 2, z: 2 });
        vm.prank(admin);
        craftObject.createObject(existingTokenId, newUri, newSize, tempTreasury, 10);
    }

    function testFail_objectCreation_notOwner() public {
        uint256 newTokenId = 100_002;
        string memory newUri = "F8ommXdN7ls6ZubQZvxvBstgdWkPGBm081urvD0YHT";
        BaseObject.Size memory newSize = BaseObject.Size({ x: 2, y: 2, z: 2 });
        address notOwner = address(0x789);
        vm.prank(notOwner);
        vm.expectRevert("MustBeOwner()");
        craftObject.createObject(newTokenId, newUri, newSize, tempTreasury, 10);
    }

    function testFail_getObject_notFromCraftLogic() public {
        uint256 tokenId = 100_001;
        uint256 amount = 1;
        uint256 tempRecipeId = 1;
        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSelector(BaseObject.InvalidAddress.selector, "Destination address can't be 0"));
        craftObject.craftObject(testAddress, tempRecipeId, tokenId, amount);
    }

    function test_isApprovedForAll() public {
        // PhiMap should always be an approved operator
        assertTrue(craftObject.isApprovedForAll(admin, tempPhiMap), "PhiMap should always be an approved operator");
    }

    function test_uri() public {
        uint256 tokenId = 100_001;
        string memory expectedUri = "https://www.arweave.net/DOYHTf8ommXdN7ls6ZubQZvxvBstgdWkPGBm081urvs";
        assertEq(expectedUri, craftObject.uri(tokenId), "Should have correct URI");
    }

    function test_maxclaimd() public {
        uint256 tokenId = 100_001;
        uint256 expectedMaxClaimable = 10;
        assertEq(expectedMaxClaimable, craftObject.getMaxClaimed(tokenId), "Should be 10");
    }

    function testFail_getObject_notForSale() public {
        uint256 newTokenId = 100_002;
        string memory newUri = "F8ommXdN7ls6ZubQZvxvBstgdWkPGBm081urvD0YHT";
        BaseObject.Size memory newSize = BaseObject.Size({ x: 2, y: 2, z: 2 });

        vm.prank(admin);
        craftObject.createObject(newTokenId, newUri, newSize, tempTreasury, 10);
        craftObject.setOpenForSale(newTokenId, false);

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
        vm.expectRevert("NotForSale()");
        craftLogic.craft(1); //< create Craft Object 100001
    }

    function test_RevertIf_TreasuryAddressIsZero() public {
        vm.prank(admin);
        vm.expectRevert(
            abi.encodeWithSelector(BaseObject.InvalidAddress.selector, "Treasury address can't be zero address")
        );
        craftObject.setTreasuryAddress(payable(address(0)));
    }

    function test_RevertIf_CreatorAddressIsZero() public {
        uint256 tokenId = 100_001;

        vm.prank(admin);
        vm.expectRevert(
            abi.encodeWithSelector(BaseObject.InvalidAddress.selector, "Creator address can't be zero address")
        );
        craftObject.setCreatorAddress(tokenId, payable(address(0)));
    }

    function test_RevertIf_ShopAddressIsZero() public {
        vm.prank(admin);
        vm.expectRevert(
            abi.encodeWithSelector(BaseObject.InvalidAddress.selector, "Shop address can't be zero address")
        );
        craftObject.setShopAddress(payable(address(0)));
    }

    function test_RevertIf_WithdrawAddressIsZero() public {
        vm.prank(admin);
        vm.expectRevert(
            abi.encodeWithSelector(BaseObject.InvalidAddress.selector, "Withdraw address can't be zero address")
        );
        craftObject.withdrawOwnerBalance(payable(address(0)));
    }

    function test_RevertIf_BurnObjectCalledByUnauthorizedAddress() public {
        vm.prank(testAddress);
        vm.expectRevert(CraftableObject.UnauthorizedCaller.selector);
        craftObject.burnObject(admin, 2, 2);
    }
}
