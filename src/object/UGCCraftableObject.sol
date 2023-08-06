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

import { ReentrancyGuard } from "@openzeppelin/security/ReentrancyGuard.sol";
import { ERC1155, ERC1155Supply } from "@openzeppelin/token/ERC1155/extensions/ERC1155Supply.sol";

import { BaseUGCCraftableObject } from "../utils/BaseUGCCraftableObject.sol";

/// @title UGCCraftableObject
/// @dev The UGCCraftableObject contract inherits from BaseUGCCraftableObject.
/// It represents unique digital assets created by users.
/// These UGCCraftableObjects are created through the UGCCraftableObjectFactory and are incorporated into
/// the Phi ecosystem as materials, products, and catalysts
contract UGCCraftableObject is BaseUGCCraftableObject, ReentrancyGuard, ERC1155Supply {
    /* -------------------------------------------------------------------------- */
    /*                                   CONFIG                                   */
    /* -------------------------------------------------------------------------- */
    // Whitelist mapping for UGCCraftLogic contracts that can call craft/burn functions
    mapping(address => bool) private _whitelist;

    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */
    // Event to be emitted when an object is created.
    event CreateObject(uint256 tokenId, string uri);
    // Event to be emitted when an object is obtained.
    event LogGetObject(address indexed sender, uint256 tokenId);
    // Event to be emitted when an object is crafted.
    event LogCraftObject(address indexed sender, uint256 recipeId, uint256 tokenId, uint256 amount);

    /* -------------------------------------------------------------------------- */
    /*                                   ERRORS                                   */
    /* -------------------------------------------------------------------------- */
    error InvalidTokenID();
    error UnauthorizedCaller();
    error ReachMaxClaimable();
    error NotApprovedRecipeId(uint256, uint256);

    /* -------------------------------------------------------------------------- */
    /*                               INITIALIZATION                               */
    /* -------------------------------------------------------------------------- */
    constructor(string memory _name, string memory _symbol, address _craftLogic, address _ugcCraftLogic) ERC1155("") {
        if (_craftLogic == address(0)) revert InvalidAddress("CraftLogic address can't be 0");
        if (_ugcCraftLogic == address(0)) revert InvalidAddress("UGCCraftLogic address can't be 0");
        name = _name;
        symbol = _symbol;
        craftLogic = _craftLogic;
        ugcCraftLogic = _ugcCraftLogic;
        _whitelist[_craftLogic] = true;
        _whitelist[_ugcCraftLogic] = true;
    }

    /* -------------------------------------------------------------------------- */
    /*                                  MODIFIERS                                 */
    /* -------------------------------------------------------------------------- */

    // Modifier to ensure function can only be called by whitelisted craftLogic contracts
    modifier onlyWhitelist() {
        if (!_whitelist[_msgSender()]) revert UnauthorizedCaller();
        _;
    }

    /* -------------------------------------------------------------------------- */
    /*                                   Utility                        　        */
    /* -------------------------------------------------------------------------- */
    // Overridden function from ERC1155 to provide token URIs.
    function uri(uint256 tokenId) public view override returns (string memory) {
        if (!created[tokenId]) revert InvalidTokenID();
        return tokenURIs[tokenId];
    }

    function getTokenidCount() public view returns (uint256) {
        return tokenIdCount;
    }

    /* -------------------------------------------------------------------------- */
    /*                               Create/Mint/Burn                             */
    /* -------------------------------------------------------------------------- */
    // Allows the owner to set the token URI.
    function setTokenURI(uint256 tokenId, string memory _uri) public override onlyOwner {
        tokenURIs[tokenId] = _uri;
    }

    function setMaxClaimable(uint256 tokenId, uint256 _maxClaimable) public override onlyOwner {
        maxClaimable[tokenId] = _maxClaimable;
    }

    // Add a new function to set approval for a recipeId for crafting a specific tokenId from craftlogic.
    function setApprovalForCrafting(uint256 tokenId, uint256 recipeId, bool approval) external override onlyOwner {
        approvedForCrafting[craftLogic][tokenId][recipeId] = approval;
    }

    // Add a new function to set approval for a recipeId for crafting a specific tokenId from UGCCraftlogic.
    function setApprovalForUGCCrafting(uint256 tokenId, uint256 recipeId, bool approval) external override onlyOwner {
        approvedForCrafting[ugcCraftLogic][tokenId][recipeId] = approval;
    }

    // Function to create a new object
    function createObject(string memory tokenUri, uint256 maxClaimable) external override onlyOwner {
        uint256 tokenId = getTokenidCount() + 1;
        setTokenURI(tokenId, tokenUri);
        setMaxClaimable(tokenId, maxClaimable);
        created[tokenId] = true;
        emit CreateObject(tokenId, tokenUri);
        ++tokenIdCount;
    }

    // Allows the owner to obtain an object, minting a new one if necessary.
    function getObject(address to, uint256 tokenId, uint256 amount) external override onlyOwner nonReentrant {
        // Check if the function caller is not an zero account address
        if (!created[tokenId]) revert InvalidTokenID();
        if (to == address(0)) revert InvalidAddress("Destination address can't be 0");
        if ((super.totalSupply(tokenId) + amount) > maxClaimable[tokenId]) revert ReachMaxClaimable();
        // Mint the token
        super._mint(to, tokenId, amount, "");
        emit LogGetObject(_msgSender(), tokenId);
    }

    // Function to craft an object, usually called from CraftLogic contract
    function craftObject(
        address to,
        uint256 recipeId,
        uint256 tokenId,
        uint256 amount
    )
        external
        override
        nonReentrant
        onlyWhitelist
    {
        // Check if the function caller is not an zero account address
        if (to == address(0)) revert InvalidAddress("Destination address can't be 0");
        if (!created[tokenId]) revert InvalidTokenID();
        if ((super.totalSupply(tokenId) + amount) > maxClaimable[tokenId]) revert ReachMaxClaimable();
        // Check if the recipeId is approved for crafting the tokenId
        if (!approvedForCrafting[_msgSender()][tokenId][recipeId]) revert NotApprovedRecipeId(tokenId, recipeId);

        // Mint the token
        super._mint(to, tokenId, amount, "");
        emit LogCraftObject(_msgSender(), recipeId, tokenId, amount);
    }

    // Function to burn an object
    function burnObject(address from, uint256 tokenId, uint256 amount) external onlyWhitelist {
        super._burn(from, tokenId, amount);
    }
}
