// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/// @title Packed 2 Uint128 to Uint256
/// @author Kiwari Labs

library P2U128 {
    function pack(uint128 lb, uint128 ub) internal pure returns (uint256 result) {
        assembly {
            result := or(shl(0x80, lb), ub)
        }
    }

    function unpack(uint256 p) internal pure returns (uint128 ub, uint128 lb) {
        assembly {
            lb := and(p, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            ub := shr(0x80, p)
        }
    }
}

