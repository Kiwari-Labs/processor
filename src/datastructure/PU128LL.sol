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
        uint128 md; // enabling traversal one direction only 'next' when perform insert and remove
        mapping(uint256 => uint256) n;
    }

    uint8 private constant sn = 0;

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
            c = uint128(l.n[c]);
        }
    }

    function rlist(List storage l) internal view returns (uint128[] memory lm) {
        lm = new uint128[](l.s);
        uint128 c = back(l);

        for (uint128 i = 0; c != sn; i++) {
            lm[i] = c;
            c = uint128(l.n[c] >> 128);
        }
    }

    /// @custom:gas-inefficiency O(n/2)
    function remove(List storage l, uint128 e) internal returns (bool r) {
        if (find(l, e)) {
            (uint128 f, uint128 b) = get(l, sn);
            uint128 mid = l.md;
            uint128 s = l.s;
            if (s == 1) {
                l.n[sn] = 0;
                l.md = 0;
            } else if (e == f) {
                // pop_front
                (, uint128 b) = get(l, sn);
                (uint128 af, ) = get(l, e);
                (uint128 afx, ) = get(l, af);
                set(l, sn, af, b); // set sentinel node{next:after element, prev:back}
                set(l, af, afx, sn); // set new front node{next:after front, prev:sentinel}
            } else if (e == b) {
                // pop_back
                (uint128 f, ) = get(l, sn);
                (, uint128 bf) = get(l, e);
                (, uint128 bfx) = get(l, bf);
                set(l, sn, f, bf); // set sentinel node{next:front, prev:before element}
                set(l, bf, sn, bfx); // set new back node{next:sentinel, prev:before back}
            } else {
                uint128 cur;
                if (e > mid) {
                    cur = f;
                    while (cur < e) {
                        (cur, ) = get(l, cur);
                    }
                }
                if (e < mid) {
                    cur = b;
                    while (cur > e) {
                        (, cur) = get(l, cur);
                    }
                }
                (uint128 n, uint128 p) = get(l, cur);
                (, uint128 bfx) = get(l, n);
                (uint128 afx, ) = get(l, p);
                set(l, p, n, bfx);
                set(l, n, afx, p);
            }
            l.n[e] = 0;
            l.s = s - 1;
            if (s > 1) {
                if (s & 2 == 0) {
                    (, mid) = get(l, mid); // move midpoint backward
                } else {
                    (mid, ) = get(l, mid); // move midpoint forward
                }
                l.md = mid;
            }
            r = true;
        }
    }

    /// @custom:gas-inefficiency O(n/2)
    function insert(List storage l, uint128 e) internal returns (bool r) {
        if (!find(l, e)) {
            uint128 s = l.s;
            if (s == 0) {
                set(l, sn, e, e); // set sentinel
                set(l, e, sn, sn); // set element
                l.md = e; // set mid
            } else {
                (uint128 f, uint128 b) = get(l, sn);
                uint128 mid = l.md;
                if (e < f) {
                    // push_front
                    (uint128 af, ) = get(l, f);
                    set(l, e, f, sn); // set element node{next:front, prev:sentinel}
                    set(l, sn, e, b); // set sentinel node{next:element, prev:back}
                    set(l, f, af, e); // set old front node{next:after front, prev:element}
                    if (s & 2 == 0) {
                        (, mid) = get(l, mid); // Move midpoint backward
                    }
                } else if (e > b) {
                    // push_back
                    (, uint128 bf) = get(l, b);
                    set(l, e, sn, b); // set element node{next:sentinel, prev:back}
                    set(l, sn, f, e); // set sentinel node{next:front, prev:element}
                    set(l, b, e, bf); // set old back node{next:element prev:before back}
                    if (s & 2 == 1) {
                        (mid, ) = get(l, l.md); // move midpoint forward
                    }
                } else {
                    uint128 cur;
                    if (e < mid) {
                        (, mid) = get(l, mid);
                        cur = f;
                        while (e > cur) {
                            (cur, ) = get(l, cur);
                        }
                    }
                    if (e > mid) {
                        (mid, ) = get(l, mid);
                        cur = b;
                        while (e < cur) {
                            (, cur) = get(l, cur);
                        }
                    }
                    (uint128 n, uint128 p) = get(l, cur);
                    set(l, e, cur, p); // set new element's next to cur and prev to p
                    set(l, p, e, n); // set previous node's next to new element and new element's next to n
                    set(l, n, e, cur); // update cur's previous to the new element
                }
                l.md = mid;
            }
            l.s = s + 1;
            r = true;
        }
    }

    function size(List storage l) internal view returns (uint128) {
        return l.s;
    }
}
