// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Packed Uint128 Linked List (PU128LL)
/// @dev Stores two 128-bit pointers (next and prev) in a single 256-bit storage slot to reduce storage accesses and costs.
/// @author Kiwari Labs

import {P2U128} from "../compression/P2U128.sol";

library PU128LL {
    using P2U128 for uint256;

    struct List {
        uint128 s;
        mapping(uint256 => uint256) n;
    }

    uint8 private constant sn = 0;
    uint128 private constant mn = type(uint128).max;

    function get(
        List storage l,
        uint128 e
    ) internal view returns (uint128 n, uint128 p) {
        return l.n[e].unpack();
    }

    function set(List storage l, uint128 e, uint128 n, uint128 p) private {
        l.n[e] = P2U128.pack(n, p);
    }

    function back(List storage l) internal view returns (uint128 b) {
        (, b) = l.n[sn].unpack();
    }

    function front(List storage l) internal view returns (uint128 f) {
        (f, ) = l.n[sn].unpack();
    }

    function find(List storage l, uint256 e) internal view returns (bool r) {
        (uint128 n, ) = l.n[sn].unpack();
        (, uint128 p) = l.n[e].unpack();
        r = p > 0 || n == e;
    }

    function list(List storage l) internal view returns (uint128[] memory lm) {
        lm = new uint128[](l.s);
        uint128 c = front(l);

        for (uint128 i = 0; c != sn; i++) {
            lm[i] = c;
            c = uint128(l.n[c] & mn); // Move to the next node
        }
    }

    function remove(List storage l, uint128 e) internal returns (bool r) {
        if (find(l, e)) {
            (uint128 f, uint128 b) = get(l, sn);
            (uint128 af, uint128 bf) = get(l, e);
            if (e == f) {
                // pop_front
                set(l, sn, af, b)
            } else if (e == b) {
                // pop_back
                set(l, sn, f, bf)
            } else {
                // pop
                // @TODO
            }
            // clear
            set(l, e, sn, sn)
            l.s--;
            r = true;
        }
    }

    function insert(List storage l, uint128 e) internal returns (bool r) {
        if (!find(l, e)) {
            if (l.s == 0) {
                // Initialize the list with the first element
                set(l, sn, e, e);
                set(l, e, sn, sn);
            } else {
                (uint128 f, uint128 b) = get(l, sn); // Direct assignment of returned tuple to `f` and `b`
                if (e < f) {
                    // push_front
                    set(l, e, f, sn); // New element points to old head
                    set(l, sn, e, b); // Sentinel's next points to new head
                    set(l, f, uint128(l.n[f]), e); // Old head’s prev points to new head
                } else if (e > b) {
                    // push_back
                    set(l, e, sn, b); // New element points to sentinel as next and old back as prev
                    set(l, sn, f, e); // Sentinel’s prev points to new back
                    set(l, b, e, uint128((l.n[b]))); // Old back’s next points to new back
                } else {
                    // push
                    // @TODO
                }
            }
            l.s++;
            r = true;
        }
    }

    function size(List storage l) internal view returns (uint128) {
        return l.s;
    }
}
