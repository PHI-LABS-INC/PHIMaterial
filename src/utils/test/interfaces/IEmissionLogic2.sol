// SPDX-License-Identifier: GPL-2.0-or-later
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

interface IEmissionLogic2 {
    function determineTokenbyLogic(uint16 logic) external view returns (uint256 tokenId);
}
