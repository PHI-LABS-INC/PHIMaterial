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

import { BaseObject } from "../utils/BaseObject.sol";

/// @title CraftableObject
// CraftableObject smart contract inherits ERC1155 interface.
// It represents unique digital assets.
// Various forms such as items or characters that can be utilized within the game of Phi.
contract CraftableObject is BaseObject, ERC1155Supply {
    /* -------------------------------------------------------------------------- */
    /*                                   CONFIG                                   */
    /* -------------------------------------------------------------------------- */
    address public immutable phiMapAddress;
    address public craftLogic;

    // Whitelist mapping for CraftLogic contracts that can call burn functions
    mapping(address => bool) private _burnWhitelist;

    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */
    // Events for creating and crafting objects, and setting the craft logic contract
    event CreateCraftableObject(uint256 tokenId, string uri, Size size, address payable creator);
    event LogCraftObject(address indexed sender, uint256 recipeId, uint256 tokenId, uint256 amount);
    event SetCraftLogic(address oldCraftLogic, address indexed newCraftLogic);
    // Event to be emitted when an address is added to the whitelist.
    event Whitelisted(address indexed sender, address indexed whitelistedAddress);
    // Event to be emitted when an address is removed from the whitelist.
    event RemovedFromWhitelist(address indexed sender, address indexed UnWhitelistedAddress);

    /* -------------------------------------------------------------------------- */
    /*                                   ERRORS                                   */
    /* -------------------------------------------------------------------------- */
    error NotOpenForSale();
    error UnauthorizedCaller();
    error ReachMaxClaimable();
    error MustBeAContract();

    /* -------------------------------------------------------------------------- */
    /*                               INITIALIZATION                               */
    /* -------------------------------------------------------------------------- */
    // Constructor sets up the name, symbol, metadata URI, treasury address,
    // PhiMap address, craftLogic, and secondaryRoyalty of the CraftableObject contract
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
        name = "Phi Craft Object";
        symbol = "Phi-COS";
        baseMetadataURI = "https://www.arweave.net/";
        treasuryAddress = _treasuryAddress;
        phiMapAddress = _phiMapAddress;
        craftLogic = _craftLogic;
        secondaryRoyalty = 1000;
        _burnWhitelist[_craftLogic] = true;
        _burnWhitelist[_ugcCraftLogic] = true;
    }

    /* -------------------------------------------------------------------------- */
    /*                                  MODIFIERS                                 */
    /* -------------------------------------------------------------------------- */
    // Modifier to ensure function can only be called by CraftLogic contracts
    modifier onlyCraftLogic() {
        if (_msgSender() != craftLogic) revert UnauthorizedCaller();
        _;
    }

    // Modifier to ensure function can only be called by whitelisted CraftLogic contracts
    modifier onlyBurnWhitelist() {
        if (!_burnWhitelist[_msgSender()]) revert UnauthorizedCaller();
        _;
    }

    /* -------------------------------------------------------------------------- */
    /*                                   PHIMAP                                   */
    /* -------------------------------------------------------------------------- */
    // Always allows PhiMap contract to move Object.
    // Then users don't need to call `setApprovalForAll`
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
    /*                                   MUTATORS                                 */
    /* -------------------------------------------------------------------------- */

    /// @dev Set a new CraftLogic contract address.
    function setCraftLogic(address _craftLogic) external onlyOwner {
        if (_craftLogic == address(0)) revert InvalidAddress("Craft Logic address can't be 0");
        if (_checkSize(_craftLogic) == 0) revert MustBeAContract();

        address oldCraftLogic = craftLogic;
        craftLogic = _craftLogic;
        emit SetCraftLogic(oldCraftLogic, craftLogic);
    }

    /* -------------------------------------------------------------------------- */
    /*                                   Utility                        　        */
    /* -------------------------------------------------------------------------- */
    function _isValid(uint256 tokenId) internal view override {
        if (tokenId == 0 || !created[tokenId]) revert InvalidTokenID();
    }

    function _checkSize(address addr) private view returns (uint256 extSize) {
        assembly {
            extSize := extcodesize(addr) // returns 0 if EOA, >0 if smart contract
        }
    }

    function addToWhitelist(address sender) external onlyOwner {
        _burnWhitelist[sender] = true;
        emit Whitelisted(msg.sender, sender);
    }

    function removeFromWhitelist(address sender) external onlyOwner {
        _burnWhitelist[sender] = false;
        emit RemovedFromWhitelist(msg.sender, sender);
    }

    /* -------------------------------------------------------------------------- */
    /*                               Create/Mint/Burn                             */
    /* -------------------------------------------------------------------------- */
    // Function to create a new object with given parameters
    function createObject(
        uint256 tokenId,
        string memory tokenUri,
        Size memory size,
        address payable creator,
        uint256 maxClaimable
    )
        external
        onlyOwner
    {
        if (exists(tokenId)) revert ExistentToken();
        setTokenURI(tokenId, tokenUri);
        setSize(tokenId, size);
        setCreatorAddress(tokenId, creator);
        setMaxClaimable(tokenId, maxClaimable);
        setOpenForSale(tokenId, true);
        created[tokenId] = true;
        emit CreateCraftableObject(tokenId, tokenUri, size, creator);
    }

    // Function to craft an object, usually called from CraftLogic contracts
    function craftObject(
        address to,
        uint256 recipeId,
        uint256 tokenId,
        uint256 amount
    )
        external
        nonReentrant
        onlyCraftLogic
    {
        // Check if the token id exists
        _isValid(tokenId);
        // Check if the function caller is not an zero address
        if (to == address(0)) revert InvalidAddress("Destination address can't be 0");
        // Check if the token is open for sale
        if (!allObjects[tokenId].forSale) revert NotOpenForSale();

        if ((super.totalSupply(tokenId) + amount) > allObjects[tokenId].maxClaimable) revert ReachMaxClaimable();
        // mint the token
        super._mint(to, tokenId, amount, "");
        emit LogCraftObject(_msgSender(), recipeId, tokenId, amount);
    }

    // Function to burn an object
    function burnObject(address from, uint256 tokenId, uint256 amount) external onlyBurnWhitelist {
        super._burn(from, tokenId, amount);
    }
}
