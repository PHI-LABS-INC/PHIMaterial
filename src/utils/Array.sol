// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Coupon } from "../types/Coupon.sol";

library CouponArray {
    /**
     * @dev Returns true if the array contains duplicated coupons.
     */
    function hasDuplicate(Coupon[] memory coupons) internal pure returns (bool) {
        if (coupons.length <= 1) return false;

        uint256 length = coupons.length;
        for (uint256 i; i < length;) {
            for (uint256 j = i + 1; j < length;) {
                if (_equals(coupons[i], coupons[j])) {
                    return true;
                }
                unchecked {
                    ++j;
                }
            }
            unchecked {
                ++i;
            }
        }
        return false;
    }

    function _equals(Coupon memory a, Coupon memory b) private pure returns (bool) {
        return a.v == b.v && a.r == b.r && a.s == b.s;
    }
}
