// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { console2 } from "forge-std/console2.sol";
import { PRBTest } from "prb-test/PRBTest.sol";
import { StdCheats } from "forge-std/StdCheats.sol";

import "../src/PhiDaily.sol";
import "../src/object/MaterialObject.sol";
import "../src/EmissionLogic.sol";

contract MaterialObjectTest is PRBTest, StdCheats {
    PhiDaily phiDaily;

    address admin = vm.addr(1);
    address adminSigner = address(0xAA9bD7C35be4915dC1F18Afad6E631f0AfCF2461);
    address tempForwarder = address(0xd8253782c45a12053594b9deB72d8e8aB2Fca54c);
    address tempGelatoRelay = 0xd8253782c45a12053594b9deB72d8e8aB2Fca54c;
    address tempCraftLogic = 0x1234567890123456789012345678901234567890;
    address tempUGCCraftLogic = 0x1234567890123456789012345678901234567890;
    MaterialObject materialObject;
    EmissionLogic emissionLogic;

    address payable tempTreasury = payable(address(0xb7Caa0ed757bbFaA208342752C9B1c541e36a4b9));
    address tempPhiMap = address(0x123);

    address testAddress = address(0x5037e7747fAa78fc0ECF8DFC526DcD19f73076ce);

    function setUp() public {
        vm.startPrank(admin);
        emissionLogic = new EmissionLogic();
        materialObject = new MaterialObject(tempTreasury, tempPhiMap, tempCraftLogic, tempUGCCraftLogic);
        materialObject.createObject(
            100_001, "DOYHTf8ommXdN7ls6ZubQZvxvBstgdWkPGBm081urvs", BaseObject.Size({ x: 1, y: 1, z: 1 }), tempTreasury
        );
        phiDaily =
            new PhiDaily(adminSigner, address(materialObject), address(emissionLogic), tempForwarder, tempGelatoRelay);

        vm.stopPrank();
    }

    function test_initialOwner() public {
        assertTrue(materialObject.ownerCheck(admin), "The deployer should be an owner");
    }

    function test_setOwner() public {
        address newOwner = address(0x123);
        vm.startPrank(admin);
        materialObject.setOwner(newOwner);
        vm.stopPrank();
        assertTrue(materialObject.ownerCheck(newOwner), "The new owner should be set");
    }

    function test_removeOwner() public {
        address newOwner = address(0x123);
        vm.startPrank(admin);
        materialObject.setOwner(newOwner);
        materialObject.removeOwner(newOwner);
        vm.stopPrank();
        assertFalse(materialObject.ownerCheck(newOwner), "The owner should be removed");
    }

    function testFail_setOwner_notOwner() public {
        address notOwner = address(0x234);
        vm.prank(notOwner);
        materialObject.setOwner(notOwner);
    }

    function testFail_removeOwner_notOwner() public {
        address notOwner = address(0x234);
        vm.prank(notOwner);
        materialObject.removeOwner(notOwner);
    }

    function test_setBaseMetadataURI() public {
        string memory newBaseMetadataURI = "https://new-uri.example.com/";
        vm.prank(admin);
        materialObject.setbaseMetadataURI(newBaseMetadataURI);
        assertTrue(
            keccak256(bytes(materialObject.baseMetadataURI())) == keccak256(bytes(newBaseMetadataURI)),
            "The new base metadata URI should be set"
        );
    }

    function testFail_setBaseMetadataURI_notOwner() public {
        string memory newBaseMetadataURI = "https://new-uri.example.com/";
        address notOwner = address(0x234);
        vm.prank(notOwner);
        materialObject.setbaseMetadataURI(newBaseMetadataURI);
    }

    function test_setMaxClaimable() public {
        uint256 testTokenId = 100_001;
        uint256 newMaxClaimable = 10;
        vm.prank(admin);
        materialObject.setMaxClaimable(testTokenId, newMaxClaimable);
        assertTrue(materialObject.getMaxClaimed(testTokenId) == newMaxClaimable, "The new max claimed should be set");
    }

    function testFail_setMaxClaimable_notOwner() public {
        uint256 tokenId = 100_001;
        uint256 newMaxClaimable = 10;
        address notOwner = address(0x234);
        vm.prank(notOwner);
        materialObject.setMaxClaimable(tokenId, newMaxClaimable);
    }

    function test_setTreasuryAddress() public {
        address payable newTreasuryAddress = payable(address(0xABC));
        vm.prank(admin);
        materialObject.setTreasuryAddress(newTreasuryAddress);
        assertTrue(materialObject.treasuryAddress() == newTreasuryAddress, "The new treasury address should be set");
    }

    function testFail_setTreasuryAddress_notOwner() public {
        address payable newTreasuryAddress = payable(address(0xABC));
        address notOwner = address(0x234);
        vm.prank(notOwner);
        materialObject.setTreasuryAddress(newTreasuryAddress);
    }

    function test_changeTokenPrice() public {
        uint256 tokenId = 100_001;
        uint256 newTokenPrice = 1_000_000_000_000_000_000; // 1 ETH
        vm.prank(admin);
        materialObject.changeTokenPrice(tokenId, newTokenPrice);
        assertTrue(materialObject.getTokenPrice(tokenId) == newTokenPrice, "The new token price should be set");
    }

    function testFail_changeTokenPrice_notOwner() public {
        uint256 tokenId = 100_001;
        uint256 newTokenPrice = 1_000_000_000_000_000_000; // 1 ETH
        address notOwner = address(0x234);
        vm.prank(notOwner);
        materialObject.changeTokenPrice(tokenId, newTokenPrice);
    }

    function test_setExp() public {
        uint256 tokenId = 100_001;
        uint256 newExp = 1000;
        vm.prank(admin);
        materialObject.setExp(tokenId, newExp);
        assertTrue(materialObject.getExp(tokenId) == newExp, "The new exp should be set");
    }

    function testFail_setExp_notOwner() public {
        uint256 tokenId = 100_001;
        uint256 newExp = 1000;
        address notOwner = address(0x234);
        vm.prank(notOwner);
        materialObject.setExp(tokenId, newExp);
    }

    function test_setCreatorAddress() public {
        uint256 tokenId = 100_001;
        address payable newCreator = payable(address(0xABC));
        vm.prank(admin);
        materialObject.setCreatorAddress(tokenId, newCreator);
        assertTrue(materialObject.getCreatorAddress(tokenId) == newCreator, "The new creator address should be set");
    }

    function testFail_setCreatorAddress_notOwner() public {
        uint256 tokenId = 100_001;
        address payable newCreator = payable(address(0xABC));
        address notOwner = address(0x234);
        vm.prank(notOwner);
        materialObject.setCreatorAddress(tokenId, newCreator);
    }

    function test_setOpenForSale() public {
        uint256 tokenId = 100_001;
        bool newCheck = false;
        vm.prank(admin);
        materialObject.setOpenForSale(tokenId, newCheck);
        assertTrue(materialObject.getOpenForSale(tokenId) == newCheck, "The forSale status should be updated");
    }

    function testFail_setOpenForSale_notOwner() public {
        uint256 tokenId = 100_001;
        bool newCheck = true;
        address notOwner = address(0x234);
        vm.prank(notOwner);
        materialObject.setOpenForSale(tokenId, newCheck);
    }

    function test_setSize() public {
        uint256 tokenId = 100_001;
        BaseObject.Size memory newSize = BaseObject.Size({ x: 1, y: 2, z: 3 });
        vm.prank(admin);
        materialObject.setSize(tokenId, newSize);
        BaseObject.Size memory returnedSize = materialObject.getSize(tokenId);
        assertTrue(
            returnedSize.x == newSize.x && returnedSize.y == newSize.y && returnedSize.z == newSize.z,
            "The new size should be set"
        );
    }

    function testFail_setSize_notOwner() public {
        uint256 tokenId = 100_001;
        BaseObject.Size memory newSize = BaseObject.Size({ x: 1, y: 2, z: 3 });
        address notOwner = address(0x234);
        vm.prank(notOwner);
        materialObject.setSize(tokenId, newSize);
    }

    function test_setTokenURI() public {
        uint256 tokenId = 100_001;
        string memory newTokenURI = "https://example.com/newtokenuri";
        vm.prank(admin);
        materialObject.setTokenURI(tokenId, newTokenURI);
        assertTrue(
            keccak256(bytes(materialObject.getTokenURI(tokenId))) == keccak256(bytes(newTokenURI)),
            "The new tokenURI should be set"
        );
    }

    function testFail_setTokenURI_notOwner() public {
        uint256 tokenId = 100_001;
        string memory newTokenURI = "https://example.com/newtokenuri";
        address notOwner = address(0x234);
        vm.prank(notOwner);
        materialObject.setTokenURI(tokenId, newTokenURI);
    }

    function test_getNewCreateObjectInfo() public {
        uint256 tokenId = 100_002;
        string memory tokenUri = "DOYHTf8ommXdN7ls6ZubQZvxvBstgdWkPGBm081urvs";
        BaseObject.Size memory size = BaseObject.Size({ x: 1, y: 1, z: 1 });
        address payable creator = tempTreasury;

        vm.prank(admin);
        materialObject.createObject(tokenId, tokenUri, size, creator);

        MaterialObject.Object memory obj = materialObject.getObjectInfo(tokenId);
        assertEq(obj.tokenURI, tokenUri, "The URI is incorrect");
        assertEq(obj.size.x, size.x, "The size.x is incorrect");
        assertEq(obj.size.y, size.y, "The size.y is incorrect");
        assertEq(obj.size.z, size.z, "The size.z is incorrect");
        assertEq(obj.creator, creator, "The creator address is incorrect");
        assertEq(obj.price, 0, "The price is not 0");
        assertEq(obj.exp, 0, "The EXP is not 0");
        assertEq(obj.forSale, true, "The object is not open");
    }

    function test_createObject_AgainFor100001() public {
        uint256 tokenId = 100_001;
        string memory tokenUri = "DOYHTf8ommXdN7ls6ZubQZvxvBstgdWkPGBm081urvs";
        BaseObject.Size memory size = BaseObject.Size({ x: 1, y: 1, z: 1 });
        address payable creator = tempTreasury;

        vm.prank(admin);
        materialObject.createObject(tokenId, tokenUri, size, creator);
    }

    event LogGetMaterialObject(address indexed sender, uint256 tokenId);

    function test_EmitLogGetMaterialObject() public {
        vm.expectEmit();
        emit LogGetMaterialObject(admin, 100_001);
        vm.prank(admin);
        materialObject.getObject(testAddress, 100_001, 1);
    }

    function test_totalSupplies() public {
        vm.prank(admin);
        materialObject.getObject(testAddress, 100_001, 2);

        vm.prank(tempCraftLogic);
        materialObject.burnObject(testAddress, 100_001, 1);
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 100_001;
        tokenIds[1] = 100_002;
        uint256[] memory supplies = materialObject.totalSupplies(tokenIds);
        assertEq(supplies[0], 1, "The total supply should be 1");
        assertEq(supplies[1], 0, "The total supply should be 0");
    }

    function test_burn() public {
        uint256 existingTokenId = 100_001;
        uint256 initialSupply = materialObject.totalSupply(existingTokenId);
        vm.prank(admin);
        materialObject.getObject(testAddress, existingTokenId, 1);
        assertEq(
            initialSupply + 1, materialObject.totalSupply(existingTokenId), "The total supply should increase by 1"
        );
        vm.prank(tempCraftLogic);
        materialObject.burnObject(testAddress, existingTokenId, 1);
        assertEq(initialSupply, materialObject.totalSupply(existingTokenId), "The total supply should decrease by 1");
    }

    function test_isApprovedForAll() public {
        assertTrue(materialObject.isApprovedForAll(admin, tempPhiMap), "PhiMapAddress should be approved");
    }

    function test_uri() public {
        uint256 existingTokenId = 100_001;
        string memory tokenUri = "DOYHTf8ommXdN7ls6ZubQZvxvBstgdWkPGBm081urvs";
        string memory expectedUri = string(abi.encodePacked("https://www.arweave.net/", tokenUri));
        assertEq(materialObject.uri(existingTokenId), expectedUri, "The URI should be correct");
    }

    function test_setRoyalityFee() public {
        uint256 newRoyaltyFee = 1500; // 15%
        vm.prank(admin);
        materialObject.setRoyalityFee(newRoyaltyFee);
        assertEq(materialObject.royalityFee(), newRoyaltyFee, "The new royalty fee should be set");
    }

    function test_setSecondaryRoyalityFee() public {
        uint256 newSecondaryRoyalty = 2000; // 20%
        vm.prank(admin);
        materialObject.setSecondaryRoyalityFee(newSecondaryRoyalty);
        assertEq(materialObject.secondaryRoyalty(), newSecondaryRoyalty, "The new secondary royalty should be set");
    }

    function test_receive() public {
        uint256 amount = 10 ether;
        vm.deal(testAddress, amount);
        uint256 initialBalance = materialObject.paymentBalanceOwner();
        (bool success,) = address(materialObject).call{ value: amount }("");
        require(success, "error");
        assertEq(
            materialObject.paymentBalanceOwner(),
            initialBalance + amount,
            "The payment balance should increase by the sent amount"
        );
    }

    function test_withdrawOwnerBalance() public {
        uint256 amount = 10 ether;
        (bool success,) = address(materialObject).call{ value: amount }("");
        require(success, "error");
        uint256 initialBalance = address(admin).balance;
        vm.prank(admin);
        materialObject.withdrawOwnerBalance(address(admin));
        assertEq(
            address(admin).balance,
            initialBalance + amount,
            "The owner balance should be withdrawn to the owner's address"
        );
    }

    function testFail_uri_NonExistentTokenId() public view {
        uint256 nonExistentTokenId = 999_999; // This token ID does not exist
        materialObject.uri(nonExistentTokenId); // This should fail
    }

    function testFail_setRoyalityFee_NotAdmin() public {
        uint256 newRoyaltyFee = 1500; // 15%
        vm.expectRevert("InvalidOwner()");
        materialObject.setRoyalityFee(newRoyaltyFee); // This should fail because only the admin can set the royalty fee
    }

    function testFail_setSecondaryRoyalityFee_NotAdmin() public {
        uint256 newSecondaryRoyalty = 2000; // 20%
        vm.expectRevert("InvalidOwner()");
        materialObject.setSecondaryRoyalityFee(newSecondaryRoyalty); // This should fail because only the admin can set
            // the secondary royalty
    }

    function testFail_withdrawOwnerBalance_NotAdmin() public {
        vm.expectRevert("InvalidOwner()");
        materialObject.withdrawOwnerBalance(address(this)); // This should fail because only the admin can withdraw the
            // owner balance
    }

    function test_RevertIf_TreasuryAddressIsZero() public {
        vm.prank(admin);
        vm.expectRevert(
            abi.encodeWithSelector(BaseObject.InvalidAddress.selector, "Treasury address can't be zero address")
        );
        materialObject.setTreasuryAddress(payable(address(0)));
    }

    function test_RevertIf_CreatorAddressIsZero() public {
        uint256 tokenId = 100_001;

        vm.prank(admin);
        vm.expectRevert(
            abi.encodeWithSelector(BaseObject.InvalidAddress.selector, "Creator address can't be zero address")
        );
        materialObject.setCreatorAddress(tokenId, payable(address(0)));
    }

    function test_RevertIf_ShopAddressIsZero() public {
        vm.prank(admin);
        vm.expectRevert(
            abi.encodeWithSelector(BaseObject.InvalidAddress.selector, "Shop address can't be zero address")
        );
        materialObject.setShopAddress(payable(address(0)));
    }

    function test_RevertIf_WithdrawAddressIsZero() public {
        vm.prank(admin);
        vm.expectRevert(
            abi.encodeWithSelector(BaseObject.InvalidAddress.selector, "Withdraw address can't be zero address")
        );
        materialObject.withdrawOwnerBalance(payable(address(0)));
    }
}
