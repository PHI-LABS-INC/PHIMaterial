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

import { BaseCraftLogic } from "./utils/BaseCraftLogic.sol";

/// @title CraftLogic
/// @dev The CraftLogic smart contract enables the creation, update, and execution of crafting recipes in PHI
// It also supports actions performed on behalf of users by a trusted relay service.
contract CraftLogic is BaseCraftLogic {
    /* -------------------------------------------------------------------------- */
    /*                               INITIALIZATION                               */
    /* -------------------------------------------------------------------------- */
    constructor(address trustedForwarder, address _gelatoRelay) ERC2771Context(trustedForwarder) {
        if (_gelatoRelay == address(0)) revert InvalidAddress("gelatoRelay address can't be 0");

        gelatoRelay = _gelatoRelay;
    }

    /**
     * @dev This function creates a new recipe. It checks if the recipe already exists,
     * ensures that the materials and artifacts arrays have at least one element,
     * and emits a RecipeCreated event.
     *
     * Requirements:
     * - The caller must be the owner.
     * - The materials and artifacts arrays must not be empty.
     *
     * @param materials the materials required for the recipe
     * @param artifacts the artifacts produced by the recipe
     * @param catalyst the catalyst required for the recipe
     */
    function createRecipe(
        Material[] calldata materials,
        Artifacts[] calldata artifacts,
        Catalyst calldata catalyst
    )
        external
        override
        onlyOwner
    {
        uint256 id = getRecipeNumber() + 1;
        _createOrUpdateRecipe(id, materials, artifacts, catalyst, true, false);
        ++recipeCount;
    }

    /**
     * @dev This function updates an existing recipe. It checks if the recipe exists,
     * ensures that the materials and artifacts arrays have at least one element,
     * and emits a RecipeUpdated event.
     *
     * Requirements:
     * - The caller must be the owner.
     * - The materials and artifacts arrays must not be empty.
     *
     * @param recipeId the ID of the recipe to update
     * @param materials the materials required for the recipe
     * @param artifacts the artifacts produced by the recipe
     * @param catalyst the catalyst required for the recipe
     * @param active the status of the recipe
     */
    function updateRecipe(
        uint256 recipeId,
        Material[] memory materials,
        Artifacts[] memory artifacts,
        Catalyst calldata catalyst,
        bool active
    )
        external
        override
        onlyOwner
    {
        _createOrUpdateRecipe(recipeId, materials, artifacts, catalyst, active, true);
    }

    /**
     * @dev This function changes the status of an existing recipe. It checks if the recipe exists,
     * and emits a ChangeRecipeStatus event.
     *
     * Requirements:
     * - The caller must be the owner.
     *
     * @param recipeId the ID of the recipe to update
     * @param active the new status of the recipe
     */
    function changeRecipeStatus(uint256 recipeId, bool active) external override onlyOwner {
        // Check if the recipe already exists
        if (recipes[recipeId].id != recipeId) revert NonExistentRecipe(recipeId);

        // Update
        Recipe storage recipe = recipes[recipeId];
        recipe.active = active;
        // Emit the ChangeRecipeStatus event
        emit ChangeRecipeStatus(recipeId, active, _msgSender());
    }
}
