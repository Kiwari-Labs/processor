// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Packed Uint128 Linked List (PU128LL)
/// @dev Stores two 128-bit pointers (next and prev) in a single 256-bit storage slot to reduce storage accesses and costs.
/// @author Kiwari Labs

import {P2U128} from "../compression/P2U128.sol";

library PU128LL {
    using P2U128 for uint256;

    struct List {
        uint128 size;
        uint128 mid; // enabling traversal one direction only 'next' when perform insert and remove
        mapping(uint128 => uint256) n;
    }

    uint8 private constant sn = 0;

    function set(List storage l, uint128 e, uint128 n, uint128 p) private {
        l.n[e] = P2U128.pack(n, p);
    }

    function get(
        List storage l,
        uint128 e
    ) internal view returns (uint128 n, uint128 p) {
        return l.n[e].unpack();
    }

    function back(List storage l) internal view returns (uint128 b) {
        (, b) = l.n[sn].unpack();
    }

    function front(List storage l) internal view returns (uint128 f) {
        (f, ) = l.n[sn].unpack();
    }

    function find(List storage l, uint128 e) internal view returns (bool r) {
        (uint128 n, ) = l.n[sn].unpack();
        (, uint128 p) = l.n[e].unpack();
        assembly {
            r := or(gt(p, 0), eq(n, e))
        }
    }

    /// @custom:gas-inefficiency O(n)
    function list(List storage l) internal view returns (uint128[] memory lm) {
        lm = new uint128[](l.size);
        uint128 c = front(l);
        for (uint128 i = 0; c != sn; i++) {
            lm[i] = c;
            (c, ) = l.n[c].unpack(); // use unpack to get the next node
        }
    }

    /// @custom:gas-inefficiency O(n)
    function rlist(List storage l) internal view returns (uint128[] memory lm) {
        lm = new uint128[](l.size);
        uint128 c = back(l);
        for (uint128 i = 0; c != sn; i++) {
            lm[i] = c;
            (, c) = l.n[c].unpack(); // use unpack to get the previous node
        }
    }

    function remove(List storage l, uint128 e) internal returns (bool r) {
        if (find(l, e)) {
            uint128 s = l.size;
            uint128 mid = l.mid;
            (uint128 af, uint128 bf) = get(l, e);
            (, uint128 bfx) = get(l, bf);
            (uint128 afx, ) = get(l, af);
            set(l, bf, af, bfx);
            set(l, af, afx, bf);
            l.n[e] = 0;
            l.size = s - 1;
            // adjust midpoint 's' still old cache
            if (s % 2 == 0) {
                // If the size was even, we need to move `mid` backward if `e` was after `mid`, or keep it otherwise
                if (e > mid) {
                    (, l.mid) = get(l, mid); // move mid backward
                }
            } else {
                // If the size was odd, we need to move `mid` forward if `e` was before `mid`, or keep it otherwise
                if (e < mid) {
                    (l.mid, ) = get(l, mid); // move mid forward
                }
            }
            r = true;
        }
    }

    /// @custom:gas-inefficiency O(n/2)
    function insert(List storage l, uint128 e) internal returns (bool r) {
        if (find(l, e)) return false;
        uint128 s = l.size;
        (uint128 f, uint128 b) = get(l, sn);
        uint128 mid = l.mid;
        if (s == 0) {
            set(l, sn, e, e); // set sentinel
            set(l, e, sn, sn); // set element
            l.mid = e; // set mid
        } else if (e < f) {
            // push_front
            (uint128 af, ) = get(l, f);
            set(l, e, f, sn); // set element node{next:front, prev:sentinel}
            set(l, sn, e, b); // set sentinel node{next:element, prev:back}
            set(l, f, af, e); // set old front node{next:after front, prev:element}
            // shift midpoint only if size was odd (meaning mid needs to move back)
            if (s % 2 == 1) {
                (, l.mid) = get(l, mid); // move mid backward
            }
        } else if (e > b) {
            // push_back
            (, uint128 bf) = get(l, b);
            set(l, e, sn, b); // set element node{next:sentinel, prev:back}
            set(l, sn, f, e); // set sentinel node{next:front, prev:element}
            set(l, b, e, bf); // set old back node{next:element prev:before back}
            // shift midpoint forward only if size was even
            if (s % 2 == 0) {
                (l.mid, ) = get(l, mid); // move mid forward
            }
        } else {
            uint128 cur = e > mid ? mid : f;
            while (e > cur) {
                (cur, ) = get(l, cur);
            }
            (uint128 af, uint128 bf) = get(l, cur);
            (, uint128 bfx) = get(l, bf);
            set(l, e, cur, bf); // set new element
            set(l, cur, af, e); // update surrounding nodes
            set(l, bf, e, bfx); // update next node's prev
            // adjust midpoint based on position of new element
            if (e > mid) {
                // new element is after mid, so move mid forward if size was even
                if (s % 2 == 0) {
                    (l.mid, ) = get(l, mid); // move mid forward
                }
            } else {
                // new element is before mid, so move mid backward if size was odd
                if (s % 2 == 1) {
                    (, l.mid) = get(l, mid); // move mid backward
                }
            }
        }
        l.size = s + 1;
        r = true;
    }
}
