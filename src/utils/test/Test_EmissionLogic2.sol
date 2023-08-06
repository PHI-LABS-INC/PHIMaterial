// SPDX-License-Identifier: MIT
/* -------------------------------------------------------------------------- */
// 　NO AUDIT REQUIRED
/* -------------------------------------------------------------------------- */
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

/// @title Test_EmissionLogic2
contract Test_EmissionLogic2 {
    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                               INITIALIZATION                               */
    /* -------------------------------------------------------------------------- */
    constructor() {
        // Constructor code goes here, if any
    }

    function determineTokenByLogic(uint16 logic) public view returns (uint256 tokenId) {
        // Generate a pseudo-random number from blockchain state variables
        uint256 random = uint256(keccak256(abi.encodePacked(block.prevrandao, block.timestamp, msg.sender)));

        // Normalize the random number to [0, 1000)
        uint256 normalized = random % 1000;

        // Determine the token ID based on the normalized random number and the specified logic
        if (logic == 1) {
            return _determineTokenIdV4(normalized);
        } else {
            revert("Invalid logic value");
        }
    }

    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                           　　DetermineTokenId                              */
    /* -------------------------------------------------------------------------- */
    function _determineTokenIdV2(uint256 normalized) internal pure returns (uint256) {
        if (normalized < 1) {
            return 100_000;
        } else {
            return 100_007;
        }
    }

    function _determineTokenIdV4(uint256 normalized) internal pure returns (uint256) {
        if (normalized < 1) {
            return 100_000;
        } else {
            return 100_007;
        }
    }
}
