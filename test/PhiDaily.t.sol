// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { console2 } from "forge-std/console2.sol";
import { PRBTest } from "prb-test/PRBTest.sol";
import { StdCheats } from "forge-std/StdCheats.sol";

import "../src/PhiDaily.sol";
import "../src/EmissionLogic.sol";
import "../src/utils/test/Test_EmissionLogic2.sol";
import "../src/object/MaterialObject.sol";

contract PhiDailyTest is PRBTest, StdCheats {
    PhiDaily phiDaily;

    address admin = vm.addr(1);
    address adminSigner = address(0xAA9bD7C35be4915dC1F18Afad6E631f0AfCF2461);
    address tempForwarder = address(0xd8253782c45a12053594b9deB72d8e8aB2Fca54c);
    address tempGelatoRelay = 0xd8253782c45a12053594b9deB72d8e8aB2Fca54c;
    address tempCraftLogic = 0x1234567890123456789012345678901234567890;
    address tempUGCCraftLogic = 0x1234567890123456789012345678901234567890;
    MaterialObject materialObject;
    EmissionLogic emissionLogic;

    address tempPhiMap = address(0x123);
    address payable tempTreasury = payable(address(0xb7Caa0ed757bbFaA208342752C9B1c541e36a4b9));

    address testAddress = address(0x5037e7747fAa78fc0ECF8DFC526DcD19f73076ce);

    // for coupon test
    uint32 test_eventId = 20_230_716;
    Coupon test_logic1 = Coupon({
        r: 0xb28acb74a69bb68cc6bdfaa954bfb04444399aafed63eb432fc347037309df4c,
        s: 0x64c3246726425ae0fb4296b68c9e267fc3d853ab822bfe255396e1d43c0b25d4,
        v: 27
    });
    Coupon test_logic2 = Coupon({
        r: 0x97af76fba5294b27822b5b39db786a3b6698a0ce9cfec927a8eb95f4d67b35f0,
        s: 0x35d388220424a426489f638527ab9572c92c26a263ef325f82018877a5d326aa,
        v: 27
    });
    Coupon test_logic3 = Coupon({
        r: 0xa6142d975cec70f87eeaef182480ea955c4143d0f914c1b13ca3f42d99bcd903,
        s: 0x7a4bfa106581b908cafe51e36339ebf866a6ae7a6e52845f4df22c8c259bd5de,
        v: 27
    });
    uint256 test_timestamp = 1_689_551_000;
    uint256 test_expiresIn = 1_689_552_000;

    // Events for tests
    event SetAdminSigner(address oldAdminSigner, address indexed newAdminSigner);
    event SetMaterialObject(address oldMaterialContract, address indexed newMaterialContract);
    event SetEmissionLogic(address oldEmissionLogic, address indexed newEmissionLogic);

    function setUp() public {
        vm.startPrank(admin);

        materialObject = new MaterialObject(tempTreasury, tempPhiMap, tempCraftLogic, tempUGCCraftLogic);
        emissionLogic = new EmissionLogic();
        phiDaily =
            new PhiDaily(adminSigner, address(materialObject), address(emissionLogic), tempForwarder, tempGelatoRelay);
        materialObject.setOwner(address(phiDaily));
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
        vm.stopPrank();
    }

    function test_Constructor() external {
        assertEq(phiDaily.adminSigner(), adminSigner);
    }

    function test_Deployment() public {
        assertEq(phiDaily.adminSigner(), adminSigner);
        assertEq(phiDaily.emissionLogic(), address(emissionLogic));
        assertEq(phiDaily.materialObject(), address(materialObject));
    }

    function test_claimMaterialObject() public {
        vm.warp(test_timestamp);

        vm.prank(testAddress);
        Coupon memory coupon = test_logic1;
        // Event ID and Logic ID are set to 1 for the purpose of this test.
        phiDaily.claimMaterialObject(test_eventId, 1, coupon, test_expiresIn);

        // Check the claim status
        uint256 count = phiDaily.checkClaimCount(testAddress);
        assertEq(count, 1, "The claimed count should be incremented by 1");

        uint256 eachCount = phiDaily.checkClaimEachCount(testAddress, 100_003);
        assertEq(eachCount, 1, "The claimed each count should be incremented by 1");

        uint256 status1 = phiDaily.checkClaimStatus(testAddress, test_eventId, 1);
        assertEq(status1, 1, "Logic 1: The daily claimed status should be set to _CLAIMED");

        uint256 status2 = phiDaily.checkClaimStatus(testAddress, test_eventId, 2);
        assertEq(status2, 0, "Logic 2: The daily claimed status should be set to _CLAIMED");

        uint256 status3 = phiDaily.checkClaimStatus(testAddress, test_eventId, 3);
        assertEq(status3, 0, "Logic 3: The daily claimed status should be set to _CLAIMED");
    }

    function test_claimaterialObjec_withLogic1And2() public {
        vm.warp(test_timestamp);
        Coupon memory coupon1 = test_logic1;
        Coupon memory coupon2 = test_logic2;
        vm.startPrank(testAddress);
        phiDaily.claimMaterialObject(test_eventId, 1, coupon1, test_expiresIn);
        phiDaily.claimMaterialObject(test_eventId, 2, coupon2, test_expiresIn);
        vm.stopPrank();

        // Check the claim status
        uint256 count = phiDaily.checkClaimCount(testAddress);
        assertEq(count, 2, "The claimed count should be incremented by 1");
    }

    function test_batchClaimaterialObject_withLogic1And2() public {
        vm.warp(test_timestamp);
        // Assuming these event IDs and Logic IDs have not been claimed yet
        uint32[] memory eventIds = new uint32[](2);
        eventIds[0] = test_eventId;
        eventIds[1] = test_eventId;

        uint16[] memory logicIds = new uint16[](2);
        logicIds[0] = 1;
        logicIds[1] = 2;

        Coupon[] memory coupons = new Coupon[](2);
        coupons[0] = test_logic1;
        coupons[1] = test_logic2;

        vm.startPrank(testAddress);

        phiDaily.batchClaimMaterialObject(eventIds, logicIds, coupons, test_expiresIn);
        vm.stopPrank();
        // Check the claim status for both sets of event ID and Logic ID
        for (uint256 i; i < eventIds.length; i++) {
            uint256 isClaimed = phiDaily.checkClaimStatus(testAddress, eventIds[i], logicIds[i]);
            assertEq(isClaimed, 1, "Claim status should be true for all pairs of event ID and Logic ID");
        }

        // Check the claim status
        uint256 count = phiDaily.checkClaimCount(testAddress);
        assertEq(count, 2, "The claimed count should be incremented by 1");
    }

    function testFail_batchClaimMaterialObject_withLogic1And2() public {
        vm.warp(test_timestamp);
        // Assuming these event IDs and Logic IDs have not been claimed yet
        uint32[] memory eventIds = new uint32[](2);
        eventIds[0] = test_eventId;
        eventIds[1] = test_eventId;

        uint16[] memory logicIds = new uint16[](2);
        logicIds[0] = 1;
        logicIds[1] = 2;

        Coupon[] memory coupons = new Coupon[](2);
        coupons[0] = test_logic1;
        coupons[1] = test_logic1;

        vm.prank(testAddress);
        phiDaily.batchClaimMaterialObject(eventIds, logicIds, coupons, test_expiresIn);
    }

    function testFail_AnathorLogicClaim() public {
        vm.warp(test_timestamp);
        Coupon memory coupon = test_logic1;
        vm.prank(testAddress);
        phiDaily.claimMaterialObject(test_eventId, 2, coupon, test_expiresIn);
    }

    function testFail_DoubleClaimMaterialObject() public {
        vm.warp(test_timestamp);
        Coupon memory coupon = test_logic1;
        vm.prank(testAddress);
        // Event ID and Logic ID are set to 1 for the purpose of this test.
        phiDaily.claimMaterialObject(test_eventId, 1, coupon, test_expiresIn);
        // Token ID is set to 1 for the purpose of this test.
        assertEq(phiDaily.checkClaimCount(testAddress), 1);

        phiDaily.claimMaterialObject(test_eventId, 1, coupon, test_expiresIn);
    }

    function testFail_claimMaterialObject_NotOpenForSale() public {
        vm.warp(test_timestamp);
        vm.prank(admin);
        uint256 tokenId = 100_003;
        materialObject.setOpenForSale(tokenId, false);
        Coupon memory coupon = test_logic1;
        vm.prank(testAddress);
        // Event ID and Logic ID are set to 1 for the purpose of this test.
        phiDaily.claimMaterialObject(test_eventId, 1, coupon, test_expiresIn);
    }

    function testFail_claimMaterialObject_InvalidCoupon() public {
        Coupon memory coupon = Coupon({ r: bytes32(0), s: bytes32(0), v: 0 });
        // Event ID and Logic ID are set to 1 for the purpose of this test.
        phiDaily.claimMaterialObject(1, 1, coupon, 9_999_999_999);
    }

    function testFail_claimMaterialObject_InvalidEvent() public {
        vm.warp(test_timestamp);
        //coupon for 20230607
        Coupon memory coupon = test_logic1;
        vm.prank(testAddress);
        // Event ID is set to 20230530
        phiDaily.claimMaterialObject(20_230_530, 1, coupon, test_expiresIn);
    }

    function testFail_claimMaterialObject_InvalidLogic() public {
        vm.warp(test_timestamp);
        Coupon memory coupon = test_logic1;
        vm.prank(testAddress);
        // Event ID and Logic ID are set to 1 for the purpose of this test.
        phiDaily.claimMaterialObject(test_eventId, 2, coupon, test_expiresIn);
    }

    function testFail_claimMaterialObject_InvalidExpiresIn() public {
        vm.warp(test_timestamp);
        Coupon memory coupon = test_logic1;
        vm.prank(testAddress);
        // Event ID and Logic ID are set to 1 for the purpose of this test.
        phiDaily.claimMaterialObject(test_eventId, 1, coupon, 999_999_999);
    }

    function testCheckInitialClaimedSTORGEInitial() public {
        // Check the claim status
        uint256 count = phiDaily.checkClaimCount(testAddress);
        assertEq(count, 0, "The claimed count should be 0");

        uint256 eachCount = phiDaily.checkClaimEachCount(testAddress, 100_001);
        assertEq(eachCount, 0, "The claimed each count should be 0");

        uint256 status = phiDaily.checkClaimStatus(testAddress, 20_230_531, 1);
        assertEq(status, 0, "The daily claimed status should be set to _NOT_CLAIMED");
    }

    function test_setAdminSigner_InvalidOwner() public {
        address newSigner = address(0x123);
        vm.expectRevert(MultiOwner.InvalidOwner.selector);
        phiDaily.setAdminSigner(newSigner);
    }

    function test_setEmissionLogic_InvalidOwner() public {
        address newLogic = address(0x234);
        vm.expectRevert(MultiOwner.InvalidOwner.selector);
        phiDaily.setEmissionLogic(newLogic);
    }

    function test_setMaterialObject_InvalidOwner() public {
        address newMaterialObject = address(0x345);
        vm.expectRevert(MultiOwner.InvalidOwner.selector);
        phiDaily.setMaterialObject(newMaterialObject);
    }

    function test_setAdminSigner() public {
        address newSigner = address(0x123);
        address currentSigner = phiDaily.adminSigner();

        vm.prank(admin);
        // Expect the SetAdminSigner event to be emitted
        vm.expectEmit();
        emit SetAdminSigner(currentSigner, newSigner);
        phiDaily.setAdminSigner(newSigner);

        currentSigner = phiDaily.adminSigner();
        assertEq(currentSigner, newSigner, "The admin signer should be updated");
    }

    function test_setEmissionLogic() public {
        EmissionLogic newEmissionLogic = new EmissionLogic();
        address currentLogic = phiDaily.emissionLogic();

        vm.prank(admin);
        // Expect the SetEmissionLogic event to be emitted
        vm.expectEmit();
        emit SetEmissionLogic(currentLogic, address(newEmissionLogic));
        phiDaily.setEmissionLogic(address(newEmissionLogic));

        currentLogic = phiDaily.emissionLogic();
        assertEq(currentLogic, address(newEmissionLogic), "The emission logic should be updated");
    }

    function testFail_setEmissionLogic_NotAContract() public {
        address newLogic = address(0x234);

        vm.prank(admin);
        // Expect the SetCraftLogic event to be emitted
        vm.expectRevert("MustBeAContract()");
        phiDaily.setEmissionLogic(newLogic);
    }

    function test_setMaterialObject() public {
        MaterialObject newMaterialObject =
            new MaterialObject(tempTreasury, tempPhiMap, tempCraftLogic, tempUGCCraftLogic);
        address currentMaterialObject = phiDaily.materialObject();

        vm.prank(admin);
        // Expect the SetMaterialObject event to be emitted
        vm.expectEmit();
        emit SetMaterialObject(currentMaterialObject, address(newMaterialObject));
        phiDaily.setMaterialObject(address(newMaterialObject));

        currentMaterialObject = phiDaily.materialObject();
        assertEq(currentMaterialObject, address(newMaterialObject), "The material object should be updated");
    }

    function testFail_setMaterialObject_NotAContract() public {
        address newMaterialObject = address(0x345);

        vm.prank(admin);
        // Expect the SetCraftLogic event to be emitted
        vm.expectRevert("MustBeAContract()");
        phiDaily.setMaterialObject(newMaterialObject);
    }

    function test_NewEmissionLogic() public {
        vm.warp(test_timestamp);
        Test_EmissionLogic2 emissionLogic2 = new Test_EmissionLogic2();
        vm.prank(admin);
        phiDaily.setEmissionLogic(address(emissionLogic2));

        Coupon memory coupon = test_logic1;
        vm.prank(testAddress);
        // Event ID and Logic ID are set to 1 for the purpose of this test.
        phiDaily.claimMaterialObject(test_eventId, 1, coupon, test_expiresIn);
        // Token ID is set to 1 for the purpose of this test.
        assertEq(phiDaily.checkClaimCount(testAddress), 1);

        // Check the claim status
        uint256 count = phiDaily.checkClaimCount(testAddress);
        assertEq(count, 1, "The claimed count should be incremented by 1");

        uint256 eachCount = phiDaily.checkClaimEachCount(testAddress, 100_007);
        assertEq(eachCount, 1, "The claimed each count should be incremented by 1");
    }

    function testFail_NewEmissionLogicNotExist() public {
        vm.warp(test_timestamp);
        Test_EmissionLogic2 emissionLogic2 = new Test_EmissionLogic2();
        vm.prank(admin);
        phiDaily.setEmissionLogic(address(emissionLogic2));

        Coupon memory coupon = test_logic1;
        vm.prank(testAddress);
        // Event ID and Logic ID are set to 2 for the purpose of this test.
        phiDaily.claimMaterialObject(test_eventId, 2, coupon, test_expiresIn);
    }

    event LogGetMaterialObject(address indexed sender, uint256 tokenId);

    function test_EmitLogGetMaterialObject() public {
        // Set block.prevrandao
        uint256 prevrandao = 44;
        vm.prevrandao(bytes32(prevrandao));

        // Set block.timestamp
        uint256 timestamp = 1_641_070_801;
        vm.warp(timestamp);

        vm.expectEmit();
        emit LogGetMaterialObject(address(phiDaily), 100_001);
        Coupon memory coupon = test_logic1;
        vm.prank(testAddress);
        // Event ID and Logic ID are set to 1 for the purpose of this test.
        phiDaily.claimMaterialObject(test_eventId, 1, coupon, test_expiresIn);
    }

    event LogClaimMaterialObject(address indexed sender, uint256 eventId, uint256 logicId, uint256 tokenId);

    function test_EmitLogClaimMaterialObject() public {
        // Set block.prevrandao
        uint256 prevrandao = 44;
        vm.prevrandao(bytes32(prevrandao));

        // Set block.timestamp
        uint256 timestamp = 1_641_070_801;
        vm.warp(timestamp);

        vm.expectEmit();
        emit LogClaimMaterialObject(testAddress, test_eventId, 1, 100_001);
        Coupon memory coupon = test_logic1;
        vm.prank(testAddress);
        // Event ID and Logic ID are set to 1 for the purpose of this test.
        phiDaily.claimMaterialObject(test_eventId, 1, coupon, test_expiresIn);
    }

    function test_claimMaterialObject_ExpectRevertSignatureExpired() public {
        // Set block.timestamp
        uint256 timestamp = 1_689_553_000;
        vm.warp(timestamp);
        Coupon memory coupon = test_logic1;

        vm.prank(testAddress);
        // Epected to be reverted with SignatureExpired
        vm.expectRevert(PhiDaily.SignatureExpired.selector);
        // Event ID and Logic ID are set to 1 for the purpose of this test.
        phiDaily.claimMaterialObject(test_eventId, 1, coupon, test_expiresIn);
    }

    function test_claimMaterialObject_ExpectRevertEnforcedPause() public {
        // Set block.timestamp
        uint256 timestamp = 1_641_070_801;
        vm.warp(timestamp);
        Coupon memory coupon = test_logic1;

        // Pause the contract
        vm.prank(admin);
        phiDaily.pause();

        vm.prank(testAddress);
        vm.expectRevert("Pausable: paused");
        phiDaily.claimMaterialObject(test_eventId, 1, coupon, test_expiresIn);
    }

    function test_claimMaterialObject_SuccessfulAfterUnpause() public {
        // Set block.timestamp
        uint256 timestamp = 1_641_070_801;
        vm.warp(timestamp);
        Coupon memory coupon = test_logic1;

        // Pause the contract
        vm.prank(admin);
        phiDaily.pause();

        // Try to claim material object, but it should be reverted
        vm.prank(testAddress);
        vm.expectRevert("Pausable: paused");
        phiDaily.claimMaterialObject(test_eventId, 1, coupon, test_expiresIn);

        // Unpause the contract
        vm.prank(admin);
        phiDaily.unpause();

        // Try to claim material object, and it should be successful
        vm.prank(testAddress);
        phiDaily.claimMaterialObject(test_eventId, 1, coupon, test_expiresIn);
    }

    function test_batchClaimMaterialObject_ExpectRevertSignatureExpired() public {
        // Set block.timestamp
        uint256 timestamp = 1_689_553_000;
        vm.warp(timestamp);
        Coupon memory coupon1 = test_logic1;
        // same coupon
        Coupon memory coupon2 = test_logic2;
        // Assuming these event IDs and Logic IDs have not been claimed yet
        uint32[] memory eventIds = new uint32[](2);
        eventIds[0] = test_eventId;
        eventIds[1] = test_eventId;

        uint16[] memory logicIds = new uint16[](2);
        logicIds[0] = 1;
        logicIds[1] = 2;

        Coupon[] memory coupons = new Coupon[](2);
        coupons[0] = coupon1;
        coupons[1] = coupon2;

        vm.prank(testAddress);
        // Epected to be reverted with SignatureExpired
        vm.expectRevert(PhiDaily.SignatureExpired.selector);
        phiDaily.batchClaimMaterialObject(eventIds, logicIds, coupons, test_expiresIn);
    }

    function test_batchClaimMaterialObject_ExpectRevertDuplicatedCoupons() public {
        // Set block.timestamp
        uint256 timestamp = 1_689_553_000;
        vm.warp(timestamp);
        Coupon memory coupon1 = test_logic1;
        // same coupon
        Coupon memory coupon2 = test_logic1;
        // Assuming these event IDs and Logic IDs have not been claimed yet
        uint32[] memory eventIds = new uint32[](2);
        eventIds[0] = test_eventId;
        eventIds[1] = test_eventId;

        uint16[] memory logicIds = new uint16[](2);
        logicIds[0] = 1;
        logicIds[1] = 2;

        Coupon[] memory coupons = new Coupon[](2);
        coupons[0] = coupon1;
        coupons[1] = coupon2;

        vm.prank(testAddress);
        vm.expectRevert(PhiDaily.DuplicatedCoupons.selector);
        phiDaily.batchClaimMaterialObject(eventIds, logicIds, coupons, test_expiresIn);
    }
}
