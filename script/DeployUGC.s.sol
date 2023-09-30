// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import { BaseScript } from "./Base.s.sol";
import { UGCCraftableObject } from "../src/object/UGCCraftableObject.sol";
/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting

contract DeployUGC is BaseScript {
    address payable private owner;
    address craftLogicAddress = 0x00b12c2bd5279341a97872428f1083856270c446;
    address ugcCraftLogicAddress = 0x7c79490391A5c0186018C0481C3cEF67d7ea1186;
    // Error thrown when the deployer is not the owner.

    error NotOwner();

    constructor() {
        owner = payable(msg.sender);
    }

    function run() public broadcaster returns (UGCCraftableObject ugcObject) {
        if (msg.sender != owner) revert NotOwner();

        ugcObject = new UGCCraftableObject("TEST","TES",craftLogicAddress,ugcCraftLogicAddress);
    }
}
