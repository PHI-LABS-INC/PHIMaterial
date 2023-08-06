// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import { BaseScript } from "./Base.s.sol";
import { CraftLogic } from "../src/CraftLogic.sol";
import { UGCCraftLogic } from "../src/UGCCraftLogic.sol";
import { UGCCraftableObjectFactory } from "../src/UGCCraftableObjectFactory.sol";
import { CraftableObject } from "../src/object/CraftableObject.sol";
import { MaterialObject } from "../src/object/MaterialObject.sol";
import { BaseCraftLogic } from "../src/utils/BaseCraftLogic.sol";
import { UGCCraftableObject } from "../src/object/UGCCraftableObject.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract Craft is BaseScript {
    CraftLogic craftLogic;
    UGCCraftLogic ugcCraftLogic;
    UGCCraftableObjectFactory ugcCraftableObjectFactory;
    MaterialObject materialObject;
    CraftableObject craftableObject;

    address payable private owner;
    // Need to Update after deploy
    address craftLogicAddress = 0x29a767519E9662f641a7B0b080f43E37aBc95557;
    address ugcCraftLogicAddress = 0xDaB2195DdA177A01873d648d13A5EceC3Ad14D67;
    address materialAddress = 0x27996B7f37a5455E41aE6292fd00d21df1Fb82f1;
    address craftableAddress = 0xC73ea6afE94E5E473845Db007DB11a2E8a6847e0;
    address ugcCraftableObjectFactoryAddress = 0x8D851B86cD299f9020a529A0975365eCFc1048BB;

    // Error thrown when the deployer is not the owner.
    error NotOwner();

    constructor() {
        owner = payable(msg.sender);
    }

    function run() public broadcaster returns (UGCCraftableObject ugcObject) {
        if (msg.sender != owner) revert NotOwner();

        // Define reusable variables
        BaseCraftLogic.Material[] memory materials;
        BaseCraftLogic.Artifacts[] memory artifacts;
        // Define catalyst as null
        BaseCraftLogic.Catalyst memory catalyst = BaseCraftLogic.Catalyst({
            tokenAddress: address(0),
            tokenId: 0,
            amount: 0,
            tokenType: BaseCraftLogic.TokenType.ERC20
        });

        // 1	Brick
        materials = new BaseCraftLogic.Material[](2);
        materials[0] = BaseCraftLogic.Material({ tokenAddress: materialAddress, tokenId: 100_001, amount: 1 });
        materials[1] = BaseCraftLogic.Material({ tokenAddress: materialAddress, tokenId: 100_002, amount: 1 });

        artifacts = new BaseCraftLogic.Artifacts[](1);
        artifacts[0] = BaseCraftLogic.Artifacts({ tokenAddress: craftableAddress, tokenId: 100_001, amount: 2 });

        CraftLogic(craftLogicAddress).createRecipe(materials, artifacts, catalyst);

        // 2	Brick Wall	makes a brick or brick wall
        materials = new BaseCraftLogic.Material[](2);
        materials[0] = BaseCraftLogic.Material({ tokenAddress: materialAddress, tokenId: 100_001, amount: 1 });
        materials[1] = BaseCraftLogic.Material({ tokenAddress: materialAddress, tokenId: 100_002, amount: 1 });

        artifacts = new BaseCraftLogic.Artifacts[](1);
        artifacts[0] = BaseCraftLogic.Artifacts({ tokenAddress: craftableAddress, tokenId: 100_002, amount: 2 });

        CraftLogic(craftLogicAddress).createRecipe(materials, artifacts, catalyst);

        // 3 Brick with Grass
        materials = new BaseCraftLogic.Material[](2);
        materials[0] = BaseCraftLogic.Material({ tokenAddress: materialAddress, tokenId: 100_001, amount: 1 });
        materials[1] = BaseCraftLogic.Material({ tokenAddress: materialAddress, tokenId: 100_002, amount: 2 });

        artifacts = new BaseCraftLogic.Artifacts[](1);
        artifacts[0] = BaseCraftLogic.Artifacts({ tokenAddress: craftableAddress, tokenId: 100_003, amount: 3 });

        CraftLogic(craftLogicAddress).createRecipe(materials, artifacts, catalyst);

        // 4 Brick with Flower
        materials = new BaseCraftLogic.Material[](2);
        materials[0] = BaseCraftLogic.Material({ tokenAddress: materialAddress, tokenId: 100_001, amount: 1 });
        materials[1] = BaseCraftLogic.Material({ tokenAddress: materialAddress, tokenId: 100_002, amount: 3 });

        artifacts = new BaseCraftLogic.Artifacts[](1);
        artifacts[0] = BaseCraftLogic.Artifacts({ tokenAddress: craftableAddress, tokenId: 100_004, amount: 3 });

        CraftLogic(craftLogicAddress).createRecipe(materials, artifacts, catalyst);

        // 5 Brick with Coins
        materials = new BaseCraftLogic.Material[](3);
        materials[0] = BaseCraftLogic.Material({ tokenAddress: materialAddress, tokenId: 100_001, amount: 1 });
        materials[1] = BaseCraftLogic.Material({ tokenAddress: materialAddress, tokenId: 100_002, amount: 1 });
        materials[2] = BaseCraftLogic.Material({ tokenAddress: materialAddress, tokenId: 100_006, amount: 1 });

        artifacts = new BaseCraftLogic.Artifacts[](1);
        artifacts[0] = BaseCraftLogic.Artifacts({ tokenAddress: craftableAddress, tokenId: 100_005, amount: 1 });

        CraftLogic(craftLogicAddress).createRecipe(materials, artifacts, catalyst);

        // 6 Brick with Trees
        materials = new BaseCraftLogic.Material[](1);
        materials[0] = BaseCraftLogic.Material({ tokenAddress: craftableAddress, tokenId: 100_001, amount: 2 });

        artifacts = new BaseCraftLogic.Artifacts[](1);
        artifacts[0] = BaseCraftLogic.Artifacts({ tokenAddress: craftableAddress, tokenId: 100_006, amount: 1 });

        CraftLogic(craftLogicAddress).createRecipe(materials, artifacts, catalyst);

        // 7 Brick Wall Half
        materials = new BaseCraftLogic.Material[](1);
        materials[0] = BaseCraftLogic.Material({ tokenAddress: craftableAddress, tokenId: 100_002, amount: 1 });

        artifacts = new BaseCraftLogic.Artifacts[](1);
        artifacts[0] = BaseCraftLogic.Artifacts({ tokenAddress: craftableAddress, tokenId: 100_007, amount: 2 });

        CraftLogic(craftLogicAddress).createRecipe(materials, artifacts, catalyst);

        // 8 Brick Stairs
        materials = new BaseCraftLogic.Material[](1);
        materials[0] = BaseCraftLogic.Material({ tokenAddress: craftableAddress, tokenId: 100_002, amount: 1 });

        artifacts = new BaseCraftLogic.Artifacts[](1);
        artifacts[0] = BaseCraftLogic.Artifacts({ tokenAddress: craftableAddress, tokenId: 100_008, amount: 1 });

        CraftLogic(craftLogicAddress).createRecipe(materials, artifacts, catalyst);

        // 9 Cloud Short
        materials = new BaseCraftLogic.Material[](1);
        materials[0] = BaseCraftLogic.Material({ tokenAddress: materialAddress, tokenId: 100_002, amount: 2 });

        artifacts = new BaseCraftLogic.Artifacts[](1);
        artifacts[0] = BaseCraftLogic.Artifacts({ tokenAddress: craftableAddress, tokenId: 100_009, amount: 1 });

        CraftLogic(craftLogicAddress).createRecipe(materials, artifacts, catalyst);

        // 10 Cloud Long
        materials = new BaseCraftLogic.Material[](1);
        materials[0] = BaseCraftLogic.Material({ tokenAddress: materialAddress, tokenId: 100_002, amount: 3 });

        artifacts = new BaseCraftLogic.Artifacts[](1);
        artifacts[0] = BaseCraftLogic.Artifacts({ tokenAddress: craftableAddress, tokenId: 100_010, amount: 1 });

        CraftLogic(craftLogicAddress).createRecipe(materials, artifacts, catalyst);

        ugcObject = UGCCraftableObjectFactory(ugcCraftableObjectFactoryAddress).createUGCCraftableObject(
            "PHI UGC Craftable Object", "PHI-UGC"
        );
        ugcObject.createObject("https://www.arweave.net/QPR7mgko-_xFhhdrHD6VKH9FplfDpg8tbgBo8gTRrzw", 10);
        ugcObject.createObject("https://www.arweave.net/8EXw9SzWprUbipBDvQ4MbkjPowoVCGu7wByEMUqkG54", 20);
        ugcObject.createObject("https://www.arweave.net/zZ_LFAGVtFB1mN3fqR8lSIHPVsXjr2q9GFdGf1ImdzM", 50);
        ugcObject.createObject("https://www.arweave.net/mpzx0NpPgeSFdFU6DpLEo6IxBHf1SH6ExVra-euZ28Y", 100);
        ugcObject.createObject("https://www.arweave.net/ZcPpfPvAUgBwd_N3dBOHFiOHCnjKx510XD2IgeSOgig", 1);

        // 1	Cubo
        BaseCraftLogic.Material[] memory materialsA = new BaseCraftLogic.Material[](3);
        materialsA[0] = BaseCraftLogic.Material({ tokenAddress: materialAddress, tokenId: 100_001, amount: 10 });
        materialsA[1] = BaseCraftLogic.Material({ tokenAddress: materialAddress, tokenId: 100_002, amount: 4 });
        materialsA[2] = BaseCraftLogic.Material({ tokenAddress: materialAddress, tokenId: 100_007, amount: 1 });

        BaseCraftLogic.Artifacts[] memory artifactsA = new BaseCraftLogic.Artifacts[](1);
        artifactsA[0] = BaseCraftLogic.Artifacts({ tokenAddress: address(ugcObject), tokenId: 1, amount: 1 });

        UGCCraftLogic(ugcCraftLogicAddress).createRecipe(materialsA, artifactsA, catalyst);

        // 2	Rosie
        BaseCraftLogic.Material[] memory materialsB = new BaseCraftLogic.Material[](4);
        materialsB[0] = BaseCraftLogic.Material({ tokenAddress: materialAddress, tokenId: 100_002, amount: 4 });
        materialsB[1] = BaseCraftLogic.Material({ tokenAddress: materialAddress, tokenId: 100_003, amount: 2 });
        materialsB[2] = BaseCraftLogic.Material({ tokenAddress: materialAddress, tokenId: 100_005, amount: 1 });
        materialsB[3] = BaseCraftLogic.Material({ tokenAddress: materialAddress, tokenId: 100_006, amount: 1 });

        BaseCraftLogic.Artifacts[] memory artifactsB = new BaseCraftLogic.Artifacts[](1);
        artifactsB[0] = BaseCraftLogic.Artifacts({ tokenAddress: address(ugcObject), tokenId: 2, amount: 1 });

        UGCCraftLogic(ugcCraftLogicAddress).createRecipe(materialsB, artifactsB, catalyst);

        // 3	Maxie
        BaseCraftLogic.Material[] memory materialsC = new BaseCraftLogic.Material[](4);
        materialsC[0] = BaseCraftLogic.Material({ tokenAddress: materialAddress, tokenId: 100_003, amount: 4 });
        materialsC[1] = BaseCraftLogic.Material({ tokenAddress: materialAddress, tokenId: 100_004, amount: 3 });
        materialsC[2] = BaseCraftLogic.Material({ tokenAddress: materialAddress, tokenId: 100_005, amount: 1 });
        materialsC[3] = BaseCraftLogic.Material({ tokenAddress: materialAddress, tokenId: 100_006, amount: 1 });

        BaseCraftLogic.Artifacts[] memory artifactsC = new BaseCraftLogic.Artifacts[](1);
        artifactsC[0] = BaseCraftLogic.Artifacts({ tokenAddress: address(ugcObject), tokenId: 3, amount: 1 });

        UGCCraftLogic(ugcCraftLogicAddress).createRecipe(materialsC, artifactsC, catalyst);

        // 4	Jester
        BaseCraftLogic.Material[] memory materialsD = new BaseCraftLogic.Material[](3);
        materialsD[0] = BaseCraftLogic.Material({ tokenAddress: materialAddress, tokenId: 100_005, amount: 3 });
        materialsD[1] = BaseCraftLogic.Material({ tokenAddress: materialAddress, tokenId: 100_006, amount: 2 });
        materialsD[2] = BaseCraftLogic.Material({ tokenAddress: materialAddress, tokenId: 100_007, amount: 1 });

        BaseCraftLogic.Artifacts[] memory artifactsD = new BaseCraftLogic.Artifacts[](1);
        artifactsD[0] = BaseCraftLogic.Artifacts({ tokenAddress: address(ugcObject), tokenId: 4, amount: 1 });

        UGCCraftLogic(ugcCraftLogicAddress).createRecipe(materialsD, artifactsD, catalyst);

        // 5	Cuboxie
        BaseCraftLogic.Material[] memory materialsE = new BaseCraftLogic.Material[](2);
        materialsE[0] = BaseCraftLogic.Material({ tokenAddress: address(ugcObject), tokenId: 1, amount: 1 });
        materialsE[1] = BaseCraftLogic.Material({ tokenAddress: address(ugcObject), tokenId: 3, amount: 1 });

        BaseCraftLogic.Artifacts[] memory artifactsE = new BaseCraftLogic.Artifacts[](1);
        artifactsE[0] = BaseCraftLogic.Artifacts({ tokenAddress: address(ugcObject), tokenId: 5, amount: 1 });

        UGCCraftLogic(ugcCraftLogicAddress).createRecipe(materialsE, artifactsE, catalyst);
    }
}
