// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import { BaseScript } from "./Base.s.sol";
import { UGCCraftableObject } from "../src/object/UGCCraftableObject.sol";
/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting

contract DeployUGC is BaseScript {
    address payable private owner;
    address craftLogicAddress = 0x29a767519E9662f641a7B0b080f43E37aBc95557;
    address ugcCraftLogicAddress = 0xDaB2195DdA177A01873d648d13A5EceC3Ad14D67;
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
