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

import { ERC1155, ERC1155Supply } from "@openzeppelin/token/ERC1155/extensions/ERC1155Supply.sol";
import { Pausable } from "@openzeppelin/security/Pausable.sol";

import { BaseObject } from "../utils/BaseObject.sol";

/// @title MaterialObject
// MaterialObject smart contract inherits ERC1155 interface.
contract MaterialObject is BaseObject, Pausable, ERC1155Supply {
    /* -------------------------------------------------------------------------- */
    /*                                   CONFIG                                   */
    /* -------------------------------------------------------------------------- */
    address public immutable phiMapAddress;

    // Whitelist mapping for CraftLogic/UGCCraftLogic contracts
    mapping(address => bool) private _burnWhitelist;

    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */
    event CreateMaterialObject(uint256 tokenId, string uri, Size size, address payable creator);
    event LogGetMaterialObject(address indexed sender, uint256 tokenId);
    // Event to be emitted when an address is added to the whitelist.
    event AddedToWhitelist(address indexed sender, address indexed whitelistedAddress);
    // Event to be emitted when an address is removed from the whitelist.
    event RemovedFromWhitelist(address indexed sender, address indexed unwhitelistedAddress);

    /* -------------------------------------------------------------------------- */
    /*                                   ERRORS                                   */
    /* -------------------------------------------------------------------------- */
    error NotOpenForSale();
    error GetFuncIsPaused();
    error UnauthorizedCaller();

    /* -------------------------------------------------------------------------- */
    /*                               INITIALIZATION                               */
    /* -------------------------------------------------------------------------- */
    constructor(
        address payable _treasuryAddress,
        address _phiMapAddress,
        address _craftLogic,
        address _ugcCraftLogic
    )
        ERC1155("")
    {
        if (_treasuryAddress == address(0)) revert InvalidAddress("Treasury address can't be 0");
        if (_phiMapAddress == address(0)) revert InvalidAddress("Phi Map address can't be 0");
        if (_craftLogic == address(0)) revert InvalidAddress("CraftLogic address can't be 0");
        if (_ugcCraftLogic == address(0)) revert InvalidAddress("UGCCraftLogic address can't be 0");

        name = "Phi Material Object";
        symbol = "Phi-MOS";
        baseMetadataURI = "https://www.arweave.net/";
        treasuryAddress = _treasuryAddress;
        phiMapAddress = _phiMapAddress;
        secondaryRoyalty = 1000;
        _burnWhitelist[_craftLogic] = true;
        _burnWhitelist[_ugcCraftLogic] = true;
    }

    /* -------------------------------------------------------------------------- */
    /*                                  MODIFIERS                                 */
    /* -------------------------------------------------------------------------- */
    // Modifier to ensure function can only be called by whitelisted contract
    modifier onlyBurnWhitelist() {
        if (!_burnWhitelist[_msgSender()]) revert UnauthorizedCaller();
        _;
    }

    /* --------------------------------- ****** --------------------------------- */
    /* -------------------------------------------------------------------------- */
    /*                                   PHIMAP                                   */
    /* -------------------------------------------------------------------------- */
    // always allow PhiMap contract to move Object
    // then users don't need to call `setApprovalForAll`
    // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/ERC1155.sol#L110
    function isApprovedForAll(address account, address operator) public view override returns (bool) {
        if (operator == phiMapAddress) {
            return true;
        }
        return super.isApprovedForAll(account, operator);
    }

    /* -------------------------------------------------------------------------- */
    /*                                  TOKEN URI                                 */
    /* -------------------------------------------------------------------------- */
    function uri(uint256 tokenId) public view override returns (string memory) {
        if (!created[tokenId]) revert InvalidTokenID();
        return string(abi.encodePacked(baseMetadataURI, getTokenURI(tokenId)));
    }

    /* -------------------------------------------------------------------------- */
    /*                                   Utility                        　        */
    /* -------------------------------------------------------------------------- */
    function _isValid(uint256 tokenId) internal view override {
        if (tokenId == 0 || !created[tokenId]) revert InvalidTokenID();
    }

    function addToWhitelist(address sender) external onlyOwner {
        _burnWhitelist[sender] = true;
        emit AddedToWhitelist(msg.sender, sender);
    }

    function removeFromWhitelist(address sender) external onlyOwner {
        _burnWhitelist[sender] = false;
        emit RemovedFromWhitelist(msg.sender, sender);
    }

    function totalSupplies(uint256[] memory tokenIds) external view returns (uint256[] memory) {
        uint256 length = tokenIds.length;
        uint256[] memory supplies = new uint256[](length);
        for (uint256 i; i < length;) {
            supplies[i] = super.totalSupply(tokenIds[i]);
            unchecked {
                ++i;
            }
        }

        return supplies;
    }

    /* -------------------------------------------------------------------------- */
    /*                               Create/Mint/Burn                             */
    /* -------------------------------------------------------------------------- */
    // Function to create a new object
    function createObject(
        uint256 tokenId,
        string memory tokenUri,
        Size memory size,
        address payable creator
    )
        external
        onlyOwner
    {
        if (exists(tokenId)) revert ExistentToken();
        setTokenURI(tokenId, tokenUri);
        setSize(tokenId, size);
        setCreatorAddress(tokenId, creator);
        changeTokenPrice(tokenId, 0);
        setOpenForSale(tokenId, true);
        created[tokenId] = true;
        emit CreateMaterialObject(tokenId, tokenUri, size, creator);
    }

    // Function to obtain an object. Usually call from PhiDaily contract.
    function getObject(address to, uint256 tokenId, uint256 amount) external onlyOwner nonReentrant whenNotPaused {
        // Check the token id exists
        _isValid(tokenId);
        // Check if the function caller is not an zero account address
        if (to == address(0)) revert InvalidAddress("Destination address can't be 0");
        // Check token is open for sale
        if (!allObjects[tokenId].forSale) revert NotOpenForSale();

        // Mint the token
        super._mint(to, tokenId, amount, "0x00");
        emit LogGetMaterialObject(_msgSender(), tokenId);
    }

    // Function to burn an object
    function burnObject(address from, uint256 tokenId, uint256 amount) external onlyBurnWhitelist {
        super._burn(from, tokenId, amount);
    }
}
