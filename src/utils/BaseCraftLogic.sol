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

import { ERC2771Context } from "@gelatonetwork/relay-context/contracts/vendor/ERC2771Context.sol";
import { MultiOwner } from "../utils/MultiOwner.sol";
import { ReentrancyGuard } from "@openzeppelin/security/ReentrancyGuard.sol";

import { ITokenBurner } from "../interfaces/ITokenBurner.sol";
import { ICatalyst } from "../interfaces/ICatalyst.sol";
import { ITokenCrafter } from "../interfaces/ITokenCrafter.sol";
import { IUGCCraftableObjectFactory } from "../interfaces/IUGCCraftableObjectFactory.sol";

abstract contract BaseCraftLogic is ReentrancyGuard, MultiOwner, ERC2771Context {
    /* -------------------------------------------------------------------------- */
    /*                                   CONFIG                                   */
    /* -------------------------------------------------------------------------- */
    // The address used for Gelato Relay.
    address public gelatoRelay;
    // The address used for UGCCraftableObjectFactory.
    address public ugcFactory;

    // Whitelist for material objects and artifacts that can be used in recipes
    mapping(address => bool) private _whitelist;
    /* -------------------------------------------------------------------------- */
    /*                                   STORAGE                                  */
    /* -------------------------------------------------------------------------- */
    uint256 public recipeCount;

    // Define an array to store the recipes
    mapping(uint256 => Recipe) internal recipes;

    struct Material {
        address tokenAddress; // The address of the ERC1155 contract for this material
        uint256 tokenId; // The ID of the token in the ERC1155 contract
        uint256 amount; // The amount of the token required
    }

    struct Artifacts {
        address tokenAddress; // The address of the ERC1155 contract for this Artifacts
        uint256 tokenId; // The ID of the token in the ERC1155 contract
        uint256 amount; // The amount of the token required
    }

    struct Catalyst {
        address tokenAddress; // The address of the ERC20/ERC721/ERC1155 contract for this catalyst
        uint256 tokenId; // The ID of the token in the contract : ERC20 => 0
        uint256 amount; // The required balance of the token
        TokenType tokenType; // Type of the token: 0 = ERC20, 1 = ERC721, 2 = ERC1155
    }

    struct Recipe {
        uint256 id;
        Material[] materials;
        Artifacts[] artifacts;
        Catalyst catalyst; // ERC20/ERC721/ERC1155
        address creator;
        bool active;
    }

    enum TokenType {
        ERC20,
        ERC721,
        ERC1155
    }

    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */
    // Event emitted when a new artifact is crafte
    event Crafted(address indexed crafter, uint256 recipeId);
    // Event emitted when a new recipe is created
    event RecipeCreated(uint256 indexed recipeId, address indexed owner);
    // Event emitted when a new recipe is created
    event RecipeUpdated(uint256 indexed recipeId, address indexed owner);
    // Event emitted when the GelatoRelay address is set.
    event SetGelatoRelay(address indexed oldGelatoRelay, address indexed newGelatoRelay);
    // Event emitted when the UGCFactory address is set.
    event SetUgcFactory(address indexed oldUgcFactory, address indexed ugcFactory);
    // Event emitted when a craft is performed by a relayer
    event CraftedByRelayer(uint256 indexed recipeId, address indexed relayer);
    // Event emitted when a new recipe is created
    event ChangeRecipeStatus(uint256 indexed recipeId, bool active, address indexed owner);
    // Event emitted when an address is added to the whitelist.
    event AddedToWhitelist(address indexed sender, address indexed whitelistedAddress);
    // Event emitted when an address is removed from the whitelist.
    event RemovedFromWhitelist(address indexed sender, address indexed unwhitelistedAddress);

    /* -------------------------------------------------------------------------- */
    /*                                   ERRORS                                   */
    /* -------------------------------------------------------------------------- */
    // Error thrown when an invalid address is provided. The reason for invalidity is provided as a parameter.
    error InvalidAddress(string reason);
    // Error thrown when the caller is not the creator of the recipe.
    error NotRecipeCreator(uint256 recipeId);
    // Error thrown when the required condition for a catalyst is not satisfied during crafting.
    error CatalystConditionNotSatisfied();
    // Error to throw if the function call is not made by an GelatoRelay.
    error OnlyGelatoRelay();
    // Error thrown when trying to craft using an inactive recipe.
    error RecipeInactive(uint256 recipeId);
    // Error thrown when trying to create a recipe that already exists.
    error ExistentCraft(uint256 id);
    // Error thrown when trying to update a recipe that doesn't exist.
    error NonExistentRecipe(uint256 id);
    // Error thrown when trying to create or update a recipe without any materials.
    error EmptyMaterialsArray();
    // Error thrown when trying to create or update a recipe without any artifacts.
    error EmptyArtifactsArray();
    // Error thrown if not a smart contract but an EOA
    error MustBeAContract();
    // Error thrown if an address is not whitelisted or created by UGCCraftableObjectFactory
    error MustBeWhitelistedOrCreatedByUGCFactory();

    /* -------------------------------------------------------------------------- */
    /*                                  Utility                                   */
    /* -------------------------------------------------------------------------- */

    function _checkSize(address addr) private view returns (uint256 extSize) {
        assembly {
            extSize := extcodesize(addr) // returns 0 if EOA, >0 if smart contract
        }
    }

    function _validateCraftContract(address addr) internal view {
        if (_checkSize(addr) == 0) {
            revert MustBeAContract();
        }

        if (!_whitelist[addr] && !IUGCCraftableObjectFactory(ugcFactory).checkUGCAddress(addr)) {
            revert MustBeWhitelistedOrCreatedByUGCFactory();
        }
    }

    function addToWhitelist(address addr) external onlyOwner {
        _whitelist[addr] = true;
        emit AddedToWhitelist(msg.sender, addr);
    }

    function removeFromWhitelist(address addr) external onlyOwner {
        _whitelist[addr] = false;
        emit RemovedFromWhitelist(msg.sender, addr);
    }

    /// @dev Set an UGCCraftableObjectFactory contract
    function setUgcFactory(address _ugcFactory) external onlyOwner {
        if (_ugcFactory == address(0)) {
            revert InvalidAddress({ reason: "cant set address(0)" });
        }
        if (_checkSize(_ugcFactory) == 0) revert MustBeAContract();

        address oldUgcFactory = ugcFactory;
        ugcFactory = _ugcFactory;
        emit SetUgcFactory(oldUgcFactory, ugcFactory);
    }
    /* -------------------------------------------------------------------------- */
    /*                                  MODIFIERS                                 */
    /* -------------------------------------------------------------------------- */

    modifier onlyRecipeCreator(uint256 recipeId) {
        if (_msgSender() != recipes[recipeId].creator) revert NotRecipeCreator(recipeId);
        _;
    }

    /* -------------------------------------------------------------------------- */
    /*                                    Craft                                   */
    /* -------------------------------------------------------------------------- */
    // 0:ERC20, 1:ERC721, 2:ERC1155
    function _checkCatalystCondition(Catalyst memory catalyst) internal view {
        if (catalyst.tokenType == TokenType.ERC20 && !_enoughERC20Balance(catalyst)) {
            revert CatalystConditionNotSatisfied();
        } else if (catalyst.tokenType == TokenType.ERC721 && !_correctERC721Owner(catalyst)) {
            revert CatalystConditionNotSatisfied();
        } else if (catalyst.tokenType == TokenType.ERC1155 && !_enoughERC1155Balance(catalyst)) {
            revert CatalystConditionNotSatisfied();
        }
    }

    function _enoughERC20Balance(Catalyst memory catalyst) internal view returns (bool) {
        return ICatalyst(catalyst.tokenAddress).balanceOf(_msgSender()) >= catalyst.amount;
    }

    function _correctERC721Owner(Catalyst memory catalyst) internal view returns (bool) {
        return ICatalyst(catalyst.tokenAddress).balanceOf(_msgSender()) >= catalyst.amount;
    }

    function _enoughERC1155Balance(Catalyst memory catalyst) internal view returns (bool) {
        return ICatalyst(catalyst.tokenAddress).balanceOf(_msgSender(), catalyst.tokenId) >= catalyst.amount;
    }

    /**
     * @dev This function allows users to craft an artifact with a given recipeId.
     * The function first checks if the recipe is active and satisfies the catalyst condition,
     * then it burns the required materials and mints the new artifact.
     *
     * @param recipeId ID of the recipe to be used for crafting.
     */
    function craft(uint256 recipeId) external virtual nonReentrant {
        _craft(recipeId);
    }

    function _craft(uint256 recipeId) private {
        // Retrieve the recipe
        Recipe storage recipe = recipes[recipeId];

        // Ensure the recipe is active
        if (!recipe.active) revert RecipeInactive(recipeId);

        // Check catalyst condition
        Catalyst memory catalyst = recipe.catalyst;
        if (catalyst.tokenAddress != address(0)) {
            _checkCatalystCondition(catalyst);
        }

        // Burn the required materials
        uint256 materialsLength = recipe.materials.length;
        for (uint256 i; i < materialsLength;) {
            Material memory material = recipe.materials[i];
            ITokenBurner(material.tokenAddress).burnObject(_msgSender(), material.tokenId, material.amount);
            unchecked {
                ++i;
            }
        }

        // Mint the artifacts
        uint256 artifactsLength = recipe.artifacts.length;
        for (uint256 i; i < artifactsLength;) {
            Artifacts memory artifact = recipe.artifacts[i];
            ITokenCrafter(artifact.tokenAddress).craftObject(_msgSender(), recipeId, artifact.tokenId, artifact.amount);
            unchecked {
                ++i;
            }
        }
        // Emit the Crafted event
        emit Crafted(_msgSender(), recipeId);
    }

    /* -------------------------------------------------------------------------- */
    /*                               Recipe Utility                               */
    /* -------------------------------------------------------------------------- */
    /**
     * @dev This function returns the Recipe structure for a given recipeId.
     *
     * @param recipeId ID of the recipe to be retrieved.
     */
    function getRecipe(uint256 recipeId) external view virtual returns (Recipe memory) {
        return recipes[recipeId];
    }

    // These methods need to be implemented by subclasses
    function getRecipeNumber() public view virtual returns (uint256) {
        return recipeCount;
    }

    function createRecipe(
        Material[] calldata materials,
        Artifacts[] calldata artifacts,
        Catalyst calldata catalyst
    )
        external
        virtual;

    function updateRecipe(
        uint256 recipeId,
        Material[] memory materials,
        Artifacts[] memory artifacts,
        Catalyst calldata catalyst,
        bool active
    )
        external
        virtual;

    function changeRecipeStatus(uint256 recipeId, bool active) external virtual;

    function _createOrUpdateRecipe(
        uint256 recipeId,
        Material[] memory materials,
        Artifacts[] memory artifacts,
        Catalyst calldata catalyst,
        bool active,
        bool isUpdate // true:= update, false:= create
    )
        internal
    {
        // Check if the recipe already exists
        if (recipes[recipeId].id == recipeId && !isUpdate) revert ExistentCraft(recipeId);
        if (recipes[recipeId].id != recipeId && isUpdate) revert NonExistentRecipe(recipeId);

        uint256 materialsLength = materials.length;
        uint256 artifactsLength = artifacts.length;
        // Check that materials and artifacts arrays have at least one element
        if (materialsLength == 0) revert EmptyMaterialsArray();
        if (artifactsLength == 0) revert EmptyArtifactsArray();

        if (catalyst.tokenAddress != address(0)) {
            if (_checkSize(catalyst.tokenAddress) == 0) revert MustBeAContract();
        }
        // Update or Create a new recipe
        Recipe storage recipe = recipes[recipeId];
        recipe.id = recipeId;
        recipe.creator = _msgSender();
        recipe.active = active;
        recipe.catalyst = catalyst;

        // Update the materials array
        delete recipe.materials;
        for (uint256 i; i < materialsLength;) {
            _validateCraftContract(materials[i].tokenAddress);
            recipe.materials.push(materials[i]);
            unchecked {
                ++i;
            }
        }

        // Update the artifacts array
        delete recipe.artifacts;
        for (uint256 i; i < artifactsLength;) {
            _validateCraftContract(artifacts[i].tokenAddress);
            recipe.artifacts.push(artifacts[i]);
            unchecked {
                ++i;
            }
        }
        // Emit the RecipeCreated event
        if (isUpdate) {
            emit RecipeUpdated(recipeId, _msgSender());
        } else {
            emit RecipeCreated(recipeId, _msgSender());
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                               RelayCraft                                  */
    /* -------------------------------------------------------------------------- */
    /// @dev Set a new GelatoRelay address
    function setGelatoRelay(address _gelatoRelay) external onlyOwner {
        if (_gelatoRelay == address(0)) {
            revert InvalidAddress({ reason: "cant set address(0)" });
        }
        if (_checkSize(_gelatoRelay) == 0) revert MustBeAContract();

        address oldGelatoRelay = gelatoRelay;
        gelatoRelay = _gelatoRelay;
        emit SetGelatoRelay(oldGelatoRelay, gelatoRelay);
    }

    modifier onlyGelatoRelay() {
        if (!_isGelatoRelay(msg.sender)) revert OnlyGelatoRelay();
        _;
    }

    function _isGelatoRelay(address _forwarder) internal view returns (bool) {
        return _forwarder == gelatoRelay;
    }

    // Function to craft object by relayer.
    function craftByRelayer(uint256 recipeId) external nonReentrant onlyGelatoRelay {
        _craft(recipeId);
        // Emit an event indicating that this function was called by a relayer
        emit CraftedByRelayer(recipeId, msg.sender);
    }
}
