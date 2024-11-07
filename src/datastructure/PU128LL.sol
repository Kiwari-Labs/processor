// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Packed Uint128 Linked List (PU128LL)
/// @dev Stores two 128-bit pointers (next and prev) in a single 256-bit storage slot to reduce storage accesses and costs.
/// @author Kiwari Labs

library PU128LL {
    struct List {
        uint128 size; // pack size and mind into 1
        uint128 mid; // enabling traversal one direction only 'next' when perform insert and remove
    }

    uint8 private constant sn = 0;

    uint256 constant base = 0xFFFFFF;

    function set(List storage l, uint128 e, uint128 n, uint128 p) private {
        assembly {
            sstore(xor(xor(l.slot, base), e), or(shl(0x80, p), n))
        }
    }

    function get(
        List storage l,
        uint128 e
    ) internal view returns (uint128 n, uint128 p) {
        assembly {
            let data := sload(xor(xor(l.slot, base), e))
            n := and(data, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            p := shr(0x80, data)
        }
    }

    function back(List storage l) internal view returns (uint128 b) {
        assembly {
            // let data := sload(xor(xor(l.slot, base), sn))
            b := shr(0x80, sload(xor(xor(l.slot, base), sn)))
        }
    }

    function front(List storage l) internal view returns (uint128 f) {
        assembly {
            // let data := sload(xor(xor(l.slot, base), sn))
            f := and(
                sload(xor(xor(l.slot, base), sn)),
                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
            )
        }
    }

    function find(List storage l, uint128 e) internal view returns (bool r) {
        assembly {
            let n := and(
                sload(xor(xor(l.slot, base), sn)),
                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
            )
            let p := shr(0x80, sload(xor(xor(l.slot, base), e)))
            r := or(gt(p, 0), eq(n, e))
        }
    }

    /// @custom:gas-inefficiency O(n)
    function list(List storage l) internal view returns (uint128[] memory lm) {
        lm = new uint128[](l.size);
        uint128 c = front(l);
        for (uint128 i = 0; c != sn; i++) {
            lm[i] = c;
            (c, ) = get(l, c); // use unpack to get the next node
        }
    }

    /// @custom:gas-inefficiency O(n)
    function rlist(List storage l) internal view returns (uint128[] memory lm) {
        lm = new uint128[](l.size);
        uint128 c = back(l);
        for (uint128 i = 0; c != sn; i++) {
            lm[i] = c;
            (, c) = get(l, c); // use unpack to get the next node
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
            assembly {
                sstore(xor(xor(l.slot, base), e), sn)
            }
            l.size = s - 1;
            // Adjust midpoint after removal
            if (e == mid) {
                // If the removed element was the midpoint
                if (s % 2 == 0) {
                    // If the size was even before removal, move the midpoint forward
                    l.mid = bf; // Move midpoint to the next element after the old midpoint
                } else {
                    // If the size was odd before removal, move the midpoint backward
                    l.mid = af; // Move midpoint to the previous element before the old midpoint
                }
            } else if (s > 1) {
                if (s % 2 == 0) {
                    // If the size was even before removal, we need to move the midpoint backward
                    if (e > mid) {
                        (, l.mid) = get(l, mid); // Move mid backward
                    }
                } else {
                    // If the size was odd before removal, we need to move the midpoint forward
                    if (e < mid) {
                        (l.mid, ) = get(l, mid); // Move mid forward
                    }
                }
            } else {
                // If the list is empty after removal, reset the midpoint to sentinel value (0)
                l.mid = 0;
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
