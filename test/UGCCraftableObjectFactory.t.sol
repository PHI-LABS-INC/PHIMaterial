// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { console2 } from "forge-std/console2.sol";
import { PRBTest } from "prb-test/PRBTest.sol";
import { StdCheats } from "forge-std/StdCheats.sol";

import "../src/UGCCraftableObjectFactory.sol";
import "../src/object/MaterialObject.sol";
import "../src/object/CraftableObject.sol";

import "../src/CraftLogic.sol";
import "../src/UGCCraftLogic.sol";

contract UGCCraftableObjectFactoryTest is PRBTest, StdCheats {
    CraftLogic craftLogic;
    UGCCraftLogic ugcCraftLogic;

    MaterialObject materialObject;
    UGCCraftableObjectFactory factoryContract;
    UGCCraftableObject ugcObject;

    address admin = vm.addr(1);
    address tempPhiMap = address(0x123);
    address tempForwarder = address(0xd8253782c45a12053594b9deB72d8e8aB2Fca54c);
    address tempGelatoRelay = 0xd8253782c45a12053594b9deB72d8e8aB2Fca54c;
    address payable tempTreasury = payable(address(0xb7Caa0ed757bbFaA208342752C9B1c541e36a4b9));
    address tempUGCCraftLogic = 0x1234567890123456789012345678901234567890;
    address testAddress = address(0x5037e7747fAa78fc0ECF8DFC526DcD19f73076ce);

    function setUp() public {
        vm.startPrank(admin);

        craftLogic = new CraftLogic(tempForwarder, tempGelatoRelay);
        ugcCraftLogic = new UGCCraftLogic(tempForwarder, tempGelatoRelay);

        materialObject = new MaterialObject(tempTreasury, tempPhiMap, address(craftLogic), tempUGCCraftLogic);
        materialObject.createObject(
            100_001, "DOYHTf8ommXdN7ls6ZubQZvxvBstgdWkPGBm081urvs", BaseObject.Size({ x: 1, y: 1, z: 1 }), tempTreasury
        );

        factoryContract = new UGCCraftableObjectFactory(address(craftLogic),address(ugcCraftLogic));
        vm.stopPrank();
    }

    function testCreateChildContract() public {
        vm.prank(testAddress);
        ugcObject = factoryContract.createUGCCraftableObject("test", "ZaK");
        assertEq(ugcObject.ownerCheck(testAddress), true, "The owner of the child contract should be the testAddress");
        assertEq(
            ugcObject.ownerCheck(address(factoryContract)),
            true,
            "The owner of the child contract should be the factoryContract"
        );
        assertEq(ugcObject.ownerCheck(admin), false, "The owner of the child contract should be the admin");
    }

    function testGetUGCCraftableObjectNumber() external {
        assertEq(factoryContract.getUGCCraftableObjectNumber(), 0);

        factoryContract.createUGCCraftableObject("Object1", "O1");
        assertEq(factoryContract.getUGCCraftableObjectNumber(), 1);

        factoryContract.createUGCCraftableObject("Object2", "O2");
        assertEq(factoryContract.getUGCCraftableObjectNumber(), 2);
    }

    function testGetUGCCraftableObject() external {
        UGCCraftableObject object1 = factoryContract.createUGCCraftableObject("Object1", "O1");
        UGCCraftableObject object2 = factoryContract.createUGCCraftableObject("Object2", "O2");

        assertEq(factoryContract.getUGCCraftableObject(0), address(object1));
        assertEq(factoryContract.getUGCCraftableObject(1), address(object2));
    }

    function testGetDeployedUGCCraftableObjects() external {
        address deployer = address(this);
        UGCCraftableObject object1 = factoryContract.createUGCCraftableObject("Object1", "O1");
        UGCCraftableObject object2 = factoryContract.createUGCCraftableObject("Object2", "O2");

        address[] memory deployedObjects = factoryContract.getDeployedUGCCraftableObjects(deployer);
        assertEq(deployedObjects.length, 2);
        assertEq(deployedObjects[0], address(object1));
        assertEq(deployedObjects[1], address(object2));
    }
}
