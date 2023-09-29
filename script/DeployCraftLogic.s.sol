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

    address materialAddress = 0x27996B7f37a5455E41aE6292fd00d21df1Fb82f1;
    address craftableAddress = 0xC73ea6afE94E5E473845Db007DB11a2E8a6847e0;
    address ugcCraftableObjectFactoryAddress = 0x8D851B86cD299f9020a529A0975365eCFc1048BB;

    // Error thrown when the deployer is not the owner.
    error NotOwner();

    constructor() {
        owner = payable(msg.sender);
    }

    function run() public broadcaster returns (CraftLogic craftLogic, UGCCraftLogic ugcCraftLogic) {
        if (msg.sender != owner) revert NotOwner();

        craftLogic = new CraftLogic(TRUSTED_FORWARDER_ADDRESS, GELATO_RELAY_ADDRESS);
        ugcCraftLogic = new UGCCraftLogic(TRUSTED_FORWARDER_ADDRESS, GELATO_RELAY_ADDRESS);

        craftLogic.setUgcFactory(ugcCraftableObjectFactoryAddress);
        craftLogic.addToWhitelist(materialAddress);
        craftLogic.addToWhitelist(craftableAddress);

        ugcCraftLogic.setUgcFactory(ugcCraftableObjectFactoryAddress);
        ugcCraftLogic.addToWhitelist(materialAddress);
        ugcCraftLogic.addToWhitelist(craftableAddress);
    }
}
