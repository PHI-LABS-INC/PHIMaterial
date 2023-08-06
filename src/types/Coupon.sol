// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { ECDSA } from "@openzeppelin/utils/cryptography/ECDSA.sol";

/// @notice the coupon sent was signed by the admin signer
struct Coupon {
    bytes32 r;
    bytes32 s;
    uint8 v;
}

using CouponLib for Coupon global;

library CouponLib {
    function recover(Coupon memory coupon, bytes32 digest) internal pure returns (address) {
        return ECDSA.recover(digest, abi.encodePacked(coupon.r, coupon.s, coupon.v));
    }
}
