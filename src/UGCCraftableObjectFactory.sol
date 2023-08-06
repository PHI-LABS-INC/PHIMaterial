// SPDX-License-Identifier: MIT

//                 ____    ____
//                /\___\  /\___\
//       ________/ /   /_ \/___/
//      /\_______\/   /__\___\
//     / /       /       /   /
//    / /   /   /   /   /   /
//   / /   /___/___/___/___/
//  / /   /
//  \/___/

pragma solidity 0.8.19;

import { Context } from "@openzeppelin/utils/Context.sol";

import { MultiOwner } from "./utils/MultiOwner.sol";
import { UGCCraftableObject } from "./object/UGCCraftableObject.sol";

/// @title UGCCraftableObjectFactory
/// @dev This contract is a factory for creating new UGCCraftableObject contracts.
/// It keeps track of all UGCCraftableObjects created by this factory.
contract UGCCraftableObjectFactory is Context, MultiOwner {
    /* -------------------------------------------------------------------------- */
    /*                                   CONFIG                                   */
    /* -------------------------------------------------------------------------- */
    address[] private ugcCraftableObjects;
    address public craftLogic;
    address public ugcCraftLogic;

    // Mapping from owner to list of owned UGCCraftableObjects
    mapping(address => address[]) private deployedUGCCraftableObjects;

    // Mapping from address to boolean. It is used to check if an address is created by this factory.
    mapping(address => bool) private addressMap;

    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */
    // Event to be emitted when a UGCCraftableObject is created
    event UGCCraftableObjectCreated(address deployer, address ugcCraftableObjectAddress, string name, uint256 index);
    // Event to be emitted when a new CraftLogic contract is set.
    event SetCraftLogic(address oldCraftLogic, address indexed newCraftLogic);
    // Event to be emitted when a new UGCCraftLogic contract is set.
    event SetUGCCraftLogic(address oldUGCCraftLogic, address indexed newUGCCraftLogic);

    /* -------------------------------------------------------------------------- */
    /*                                   ERRORS                                   */
    /* -------------------------------------------------------------------------- */
    // Error thrown if not a smart contract address, but an EOA.
    error MustBeAContract();
    // Error thrown if the UGCCraftableObject index is out of range.
    error InvalidIndex();
    // Error thrown when an invalid address is provided. The reason for the invalidity is provided as a parameter.
    error InvalidAddress(string reason);

    /* -------------------------------------------------------------------------- */
    /*                               INITIALIZATION                               */
    /* -------------------------------------------------------------------------- */
    // Initializes the contract by setting `CraftLogic` and `UGCCraftLogic` addresses.
    constructor(address _craftLogic, address _ugcCraftLogic) {
        if (_craftLogic == address(0)) revert InvalidAddress("CraftLogic can't be 0");
        if (_ugcCraftLogic == address(0)) revert InvalidAddress("UGCCraftLogic address can't be 0");
        craftLogic = _craftLogic;
        ugcCraftLogic = _ugcCraftLogic;
    }

    /* -------------------------------------------------------------------------- */
    /*                                   MUTATORS                                 */
    /* -------------------------------------------------------------------------- */
    function _checkSize(address addr) private view returns (uint256 extSize) {
        assembly {
            extSize := extcodesize(addr) // returns 0 if EOA, >0 if smart contract
        }
    }

    /// @dev Set a new CraftLogic address
    function setCraftLogic(address _craftLogic) external onlyOwner {
        if (_craftLogic == address(0)) revert InvalidAddress("CraftLogic address can't be 0");
        if (_checkSize(_craftLogic) == 0) revert MustBeAContract();

        address oldCraftLogic = craftLogic;
        craftLogic = _craftLogic;
        emit SetCraftLogic(oldCraftLogic, craftLogic);
    }

    /// @dev Set a new UGCCraftLogic address
    function setUGCCraftLogic(address _ugcCraftLogic) external onlyOwner {
        if (_ugcCraftLogic == address(0)) revert InvalidAddress("UGCCraftLogic address can't be 0");
        if (_checkSize(_ugcCraftLogic) == 0) revert MustBeAContract();

        address oldUGCCraftLogic = ugcCraftLogic;
        ugcCraftLogic = _ugcCraftLogic;
        emit SetUGCCraftLogic(oldUGCCraftLogic, ugcCraftLogic);
    }

    /// @dev Allows the caller to create a new UGCCraftableObject with the provided name and symbol.
    function createUGCCraftableObject(
        string memory _name,
        string memory _symbol
    )
        external
        returns (UGCCraftableObject)
    {
        UGCCraftableObject ugcObject = new UGCCraftableObject(_name, _symbol, craftLogic, ugcCraftLogic);
        addressMap[address(ugcObject)] = true;
        ugcCraftableObjects.push(address(ugcObject));
        deployedUGCCraftableObjects[_msgSender()].push(address(ugcObject));
        ugcObject.setOwner(_msgSender());

        // Emit the event after creating the UGCCraftableObject
        emit UGCCraftableObjectCreated(_msgSender(), address(ugcObject), _name, ugcCraftableObjects.length - 1);
        return ugcObject;
    }

    function checkUGCAddress(address _address) external view returns (bool) {
        return addressMap[_address];
    }

    /// @dev Allows the caller to get the total number of UGCCraftableObjects created by this factory.
    function getUGCCraftableObjectNumber() external view returns (uint256) {
        return ugcCraftableObjects.length;
    }

    /// @dev Allows the caller to get a specific UGCCraftableObject using its index.
    function getUGCCraftableObject(uint256 _index) external view returns (address) {
        if (_index >= ugcCraftableObjects.length) revert InvalidIndex();
        return ugcCraftableObjects[_index];
    }

    /// @dev Allows the caller to get all UGCCraftableObjects created by a specific deployer.
    function getDeployedUGCCraftableObjects(address _deployer) external view returns (address[] memory) {
        return deployedUGCCraftableObjects[_deployer];
    }
}
