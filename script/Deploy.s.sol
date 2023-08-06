// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import { BaseScript } from "./Base.s.sol";
import { CraftLogic } from "../src/CraftLogic.sol";
import { UGCCraftLogic } from "../src/UGCCraftLogic.sol";
import { EmissionLogic } from "../src/EmissionLogic.sol";
import { UGCCraftableObjectFactory } from "../src/UGCCraftableObjectFactory.sol";
import { PhiDaily } from "../src/PhiDaily.sol";
import { CraftableObject } from "../src/object/CraftableObject.sol";
import { MaterialObject } from "../src/object/MaterialObject.sol";
import { BaseObject } from "../src/utils/BaseObject.sol";
import { BaseCraftLogic } from "../src/utils/BaseCraftLogic.sol";
import { UGCCraftableObject } from "../src/object/UGCCraftableObject.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract Deploy is BaseScript {
    UGCCraftableObject ugcObject;

    address payable private owner;
    address public constant TRUSTED_FORWARDER_ADDRESS = 0xd8253782c45a12053594b9deB72d8e8aB2Fca54c;
    address public constant PHIMAP_ADDRESS = 0xe8b6395d223C9D3D85e162f2cb2023bC9088a908; // this is polyon-mainnet-only
    address payable public constant TREASURY_ADDRESS = payable(0x7CA1668517f4E9ce1e993fc09D07585C210Ee162);
    address public constant ADMIN_SIGNER = 0xAA9bD7C35be4915dC1F18Afad6E631f0AfCF2461;
    address payable public constant CREATOR_ADDRESS = payable(0x7CA1668517f4E9ce1e993fc09D07585C210Ee162);
    address public constant GELATO_RELAY_ADDRESS = 0xd8253782c45a12053594b9deB72d8e8aB2Fca54c;

    // Error thrown when the deployer is not the owner.
    error NotOwner();

    constructor() {
        owner = payable(msg.sender);
    }

    function run()
        public
        broadcaster
        returns (
            PhiDaily phiDaily,
            EmissionLogic emissionLogic,
            MaterialObject materialObject,
            CraftableObject craftableObject,
            CraftLogic craftLogic,
            UGCCraftLogic ugcCraftLogic,
            UGCCraftableObjectFactory ugcCraftableObjectFactory
        )
    {
        if (msg.sender != owner) revert NotOwner();

        craftLogic = new CraftLogic(TRUSTED_FORWARDER_ADDRESS, GELATO_RELAY_ADDRESS);
        ugcCraftLogic = new UGCCraftLogic(TRUSTED_FORWARDER_ADDRESS, GELATO_RELAY_ADDRESS);
        materialObject =
            new MaterialObject(TREASURY_ADDRESS, PHIMAP_ADDRESS, address(craftLogic), address(ugcCraftLogic));
        craftableObject =
            new CraftableObject(TREASURY_ADDRESS, PHIMAP_ADDRESS, address(craftLogic),address(ugcCraftLogic));
        emissionLogic = new EmissionLogic();
        ugcCraftableObjectFactory = new UGCCraftableObjectFactory(address(craftLogic),address(ugcCraftLogic));
        phiDaily = new PhiDaily(
            ADMIN_SIGNER, 
            address(materialObject), 
            address(emissionLogic), 
            TRUSTED_FORWARDER_ADDRESS, 
            GELATO_RELAY_ADDRESS
        );

        materialObject.setOwner(address(phiDaily));
        craftLogic.setUgcFactory(address(ugcCraftableObjectFactory));
        craftLogic.addToWhitelist(address(materialObject));
        craftLogic.addToWhitelist(address(craftableObject));

        ugcCraftLogic.setUgcFactory(address(ugcCraftableObjectFactory));
        ugcCraftLogic.addToWhitelist(address(materialObject));
        ugcCraftLogic.addToWhitelist(address(craftableObject));

        // Stone
        materialObject.createObject(
            100_001,
            "IorMlgDz2wATb7MVzwWHMxAZoxim0t6TNMamuX8wEYw",
            BaseObject.Size({ x: 1, y: 1, z: 1 }),
            CREATOR_ADDRESS
        );

        // Water
        materialObject.createObject(
            100_002,
            "crm9BkHYgNRlr12xkFuSHf6vE_1EuCDRw45RFMxhDSg",
            BaseObject.Size({ x: 1, y: 1, z: 1 }),
            CREATOR_ADDRESS
        );

        // Coal
        materialObject.createObject(
            100_003,
            "snJ4HdpFiu4nsZu7SqOpTMznEmLAdKlMqdv6VvgAKnE",
            BaseObject.Size({ x: 1, y: 1, z: 1 }),
            CREATOR_ADDRESS
        );

        // Copper
        materialObject.createObject(
            100_004,
            "Oo8RbrGsOrjAWR_J6B7KvQCtXzd35Qj69VInJhqWPyM",
            BaseObject.Size({ x: 1, y: 1, z: 1 }),
            CREATOR_ADDRESS
        );

        // Steal
        materialObject.createObject(
            100_005,
            "bMNc6TQweZ_VMKY5kKUQ0NeWexVwSSQUoU60DXgL_sU",
            BaseObject.Size({ x: 1, y: 1, z: 1 }),
            CREATOR_ADDRESS
        );

        // Gold
        materialObject.createObject(
            100_006,
            "GmfUt07PqLjR8ESDWxtoB2EPrEm_bK5SCPgFQRyNgHk",
            BaseObject.Size({ x: 1, y: 1, z: 1 }),
            CREATOR_ADDRESS
        );

        //Diamond
        materialObject.createObject(
            100_007,
            "nOrJdFB3uSrnHllMTmwRLLRxIVKT6nd4ozkm3JekgpA",
            BaseObject.Size({ x: 1, y: 1, z: 1 }),
            CREATOR_ADDRESS
        );

        // Brick
        craftableObject.createObject(
            100_001,
            "ZVlG1cj8YJUzpFYsVYUUijOBlcBDUfD_EywKs4LPqbs",
            BaseObject.Size({ x: 1, y: 1, z: 1 }),
            CREATOR_ADDRESS,
            999_999_999
        );

        // Brick Wall
        craftableObject.createObject(
            100_002,
            "-JTxjHYebe7wEfCBHvGEBjyPX5rsI2imaZ9qLtDrqNo",
            BaseObject.Size({ x: 1, y: 1, z: 1 }),
            CREATOR_ADDRESS,
            999_999_999
        );

        // Brick with Grass
        craftableObject.createObject(
            100_003,
            "lQAtNcp9JxmDL-759Vx90dypkHWFAJCkQ4oCJ8Z7RnY",
            BaseObject.Size({ x: 1, y: 1, z: 1 }),
            CREATOR_ADDRESS,
            999_999_999
        );

        // Brick with Flower
        craftableObject.createObject(
            100_004,
            "OOtfkFWNZCOg9nU4rtteyuTqt_Q0EChJkLCunURv3w0",
            BaseObject.Size({ x: 1, y: 1, z: 1 }),
            CREATOR_ADDRESS,
            999_999_999
        );

        // Brick with Coins
        craftableObject.createObject(
            100_005,
            "rYJ2w4Kfx97Mhy5QWVSESRdLcDjZ1aT0kbePTq2TSmo",
            BaseObject.Size({ x: 1, y: 1, z: 2 }),
            CREATOR_ADDRESS,
            999_999_999
        );

        // Brick with Trees
        craftableObject.createObject(
            100_006,
            "fpqMPuZv_w0jfBfi3WjuUjb0PXRvlyfpYc59ojbSxyg",
            BaseObject.Size({ x: 1, y: 1, z: 2 }),
            CREATOR_ADDRESS,
            999_999_999
        );

        // Brick Wall Half
        craftableObject.createObject(
            100_007,
            "I12XagE_QjhMVSInGJcYzHsoO6wcy-OuImKu4cWTzo0",
            BaseObject.Size({ x: 1, y: 1, z: 1 }),
            CREATOR_ADDRESS,
            999_999_999
        );

        // Brick Stairs
        craftableObject.createObject(
            100_008,
            "H_K4uLuyrUnaHjF1sFQ3bGKXnR4rTar5KxFz2eW0CWU",
            BaseObject.Size({ x: 1, y: 1, z: 1 }),
            CREATOR_ADDRESS,
            999_999_999
        );

        // Cloud Short
        craftableObject.createObject(
            100_009,
            "yeEe1P7WH-SNRxvhZNtPgngfMHHVukrvCEmaSCQewvc",
            BaseObject.Size({ x: 1, y: 1, z: 1 }),
            CREATOR_ADDRESS,
            999_999_999
        );

        // Cloud Long
        craftableObject.createObject(
            100_010,
            "tmZiEasC9ozfT47dxYOA3376GGT1Jy9r8U83W-DB278",
            BaseObject.Size({ x: 1, y: 2, z: 2 }),
            CREATOR_ADDRESS,
            999_999_999
        );
    }
}
