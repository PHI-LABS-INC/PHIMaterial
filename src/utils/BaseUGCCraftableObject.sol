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

import { MultiOwner } from "./MultiOwner.sol";

abstract contract BaseUGCCraftableObject is MultiOwner {
    string public name;
    string public symbol;
    address public craftLogic;
    address public ugcCraftLogic;
    uint256 public tokenIdCount;

    mapping(uint256 tokenId => string) public tokenURIs;
    mapping(uint256 tokenId => uint256) public maxClaimable;
    mapping(uint256 tokenId => bool) public created;
    mapping(address craftLogic => mapping(uint256 tokenId => mapping(uint256 recipeId => bool))) public
        approvedForCrafting;

    error InvalidAddress(string reason);

    function setTokenURI(uint256 tokenId, string memory _uri) public virtual;

    function setMaxClaimable(uint256 tokenId, uint256 maxClaimable) public virtual;

    function setApprovalForCrafting(uint256 tokenId, uint256 recipeId, bool approval) external virtual;

    function setApprovalForUGCCrafting(uint256 tokenId, uint256 recipeId, bool approval) external virtual;

    function createObject(string memory tokenUri, uint256 maxClaimable) external virtual;

    function getObject(address to, uint256 tokenId, uint256 amount) external virtual;

    function craftObject(address to, uint256 recipeId, uint256 tokenId, uint256 amount) external virtual;
}
