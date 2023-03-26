// SPDX-License-Identifier: MIT

/*
 * Library for generating dynamically- weighted discrete random variates.
 *
 * Copyright © 2023 Valorem Labs Inc.
 *
 * @author 0xAlcibiades
 * @author neodaoist
 * @author Flip-Liquid
 */

pragma solidity >=0.8.8;

import "forge-std/console.sol";

// Associated storage structures

// Represents an edge in the forest of trees
struct Edge {
    uint256 level;
    uint256 index;
}

// Represents a node in the forest of trees
struct Node {
    uint256 index;
    uint256 weight;
    Edge[] children;
}

// A level of the canopy in the forest of trees
struct Level {
    uint256 weight;
    uint256 roots;
    mapping(uint256 => Node) ranges;
}

// A struct representing the whole forest
struct Forest {
    uint256 weight;
    mapping(uint256 => Level) levels;
}

// A struct representing a FILO queue of ranges to be processed
struct Queue {
    // points to the reserved word at the head of the queue to indicate
    // which ranges have been enqueued; enqueue_range is skipped if the
    // range is already enqueued
    bytes32 ptr;
    // points to the last element in the FILO queue
    bytes32 head;
    // points to the first element in the FILO queue; items will be enqueued
    // and poppoed off at this location
    bytes32 tail;
}

// A library which takes in weights and uniform random variates and uses them
// to generate dynamically weighted discrete probability mass function random
// variates.
library LibDDRV {
    uint256 private constant fp = 0x40;
    uint256 private constant word = 0x20;

    // Preprocess an array of elements and their weights into a forest of trees.
    // TODO(This presently supports natural number weights, could easily support posits)
    function preprocess(Forest storage forest, uint256[] calldata weights) external {
        (bytes32 ptr, bytes32 head, bytes32 tail) = new_queue();

        uint256 n = weights.length;
        uint256 weight;
        uint256 i;
        uint256 j;
        for (i = 0; i < n; i++) {
            weight = weights[i];
            j = floor_ilog(weight) + 1;
            Node storage element = forest.levels[0].ranges[i];

            // Add this index to table level zero.
            element.weight = weight;
            element.index = i;
            forest.levels[0].weight += weight;

            // insert this element into the 1st-level range at index j
            Node storage destRange = insert_range(forest, element, 0, 1, j);

            // Update the forest weight overall TODO: duplicated in level[0].weight
            forest.weight += weight;

            // TODO: verify skip if range already enqueued
            tail = enqueue_range(ptr, head, tail, j, destRange);
        }

        assembly {
            // Cap off the level queue by incrementing the free memory pointer
            mstore(fp, add(tail, word))
        }

        console.log("ptr: %s", uint256(ptr));
        console.log("head: %s", uint256(head));
        console.log("tail: %s", uint256(tail));
        // Construct the forest of trees from the bottom up
        update_levels(forest, ptr, head, tail);
    }

    // Propogate upwards any changes in the the element or range weights
    function update_levels(Forest storage forest, bytes32 ptr, bytes32 head, bytes32 tail) internal {
        uint256 l = 1;

        while (head != tail) {
            // Set Qₗ₊₁
            (ptr, head, tail) = process_level_queue(forest, l, ptr, head, tail);
            // Increment level
            l += 1;
        }
    }

    // Construct a level in the forest of trees
    function process_level_queue(Forest storage forest, uint256 level, bytes32 ptr, bytes32 head, bytes32 tail)
        internal
        returns (bytes32 nextPtr, bytes32 nextHead, bytes32 nextTail)
    {
        (nextPtr, nextHead, nextTail) = new_queue();
        console.log("construct ptr: %s", uint256(ptr));
        console.log("construct head: %s", uint256(head));
        console.log("construct tail: %s", uint256(tail));

        console.log("construct level");
        // While Qₗ ≠ ∅
        while (head != tail) {
            // Dequeue range from storage
            Node storage range;
            assembly {
                range.slot := mload(head)
                head := add(word, head)
            }
            // Get weight and range number
            uint256 weight = range.weight;
            uint256 j = floor_ilog(weight) + 1;

            console.log("level: %s", level);
            console.log("weight: %s", weight);
            console.log("nextj: %s", j);
            // TODO(Support expanded degree bound)
            if (range.children.length > 1) {
                Node storage destRange = insert_range(forest, range, level, level + 1, j);
                nextTail = enqueue_range(nextPtr, nextHead, nextTail, j, destRange);

                /* TODO: Delete range(?). An explicit call to deleteRange is made in the pseudo, but
                it's unclear if this is to simply remove the weight of the range from the level, and
                to remove the range from the level table. 
                
                If the range is actually deleted, then we would need to "migrate" the children to the next
                level. So a range on level 2 could have e.g. 5 children on level 0. If this is the case, then
                the algorithm, as written, would not terminate because of the conditioninal on this branch.
                 */
            } else {
                console.log("root");
                // this is a root range with no parent
                // add range weight to level; add index to level table (roots)
                forest.levels[level].weight += weight;
                forest.levels[level].roots += 2 ** j;
            }
        }
        assembly {
            // Cap off the level queue by incrementing the free memory pointer
            mstore(fp, add(nextTail, word))
        }
    }

    // Insert the range into the forest at level, index, updating weights and edges
    function insert_range(
        Forest storage forest,
        Node storage range,
        uint256 srcLevel,
        uint256 destLevel,
        uint256 destIndex
    ) internal returns (Node storage) {
        Node storage destRange = forest.levels[destLevel].ranges[destIndex];
        // TODO: Range.index is duplicated here
        destRange.index = destIndex;
        return insert_range(forest, range, srcLevel, destRange);
    }

    // Insert the range into the forest at level, index, updating weights and edges
    function insert_range(Forest storage forest, Node storage range, uint256 srcLevel, Node storage destRange)
        internal
        returns (Node storage)
    {
        // Adds an edge from the destination range to the source
        Edge memory edge = Edge({level: srcLevel, index: range.index});
        destRange.children.push(edge);
        destRange.weight += range.weight;
        return destRange;
    }

    // Remove the supplied range fom the specified parent
    function move_range(
        Forest storage forest,
        Node storage range,
        uint256 srcLevel,
        Node storage currentParent,
        Node storage newParent
    ) internal returns (Node storage _newParent) {
        // if the current parent range is a zero range, then the supplied range
        // is being added for the first time, and no operations on the current parent
        // range are appropriate
        Level storage nextLevel = forest.levels[srcLevel + 1];
        if (currentParent.weight != 0) {
            // find and remove the edge to the supplied range in currentParent
            for (uint256 i = 0; i < currentParent.children.length; i++) {
                if (currentParent.children[i].level == srcLevel && currentParent.children[i].index == range.index) {
                    currentParent.children[i] = currentParent.children[currentParent.children.length - 1];
                    currentParent.children.pop();
                    break;
                }
            }

            // decrement the weight of the currentParent node
            currentParent.weight -= range.weight;

            // check if current parent is now a root range, updating roots and level weights
            if (is_root_range(currentParent, nextLevel)) {
                nextLevel.roots -= 2 ** currentParent.index;
            }
        }

        // unset new parent range as a root if it is one currently
        if (is_root_range(newParent, nextLevel)) {
            nextLevel.roots -= 2 ** newParent.index;
            nextLevel.weight -= newParent.weight;
        }

        // insert range into newParent
        _newParent = insert_range(forest, range, srcLevel, newParent);

        // set new parent range as a root if it is one now
        if (is_root_range(_newParent, nextLevel)) {
            nextLevel.roots += 2 ** _newParent.index;
            nextLevel.weight += _newParent.weight;
        }
    }

    function new_queue() internal returns (bytes32 ptr, bytes32 head, bytes32 tail) {
        // Set up an in memory queue object
        // Qₗ = ∅ OR Qₗ₊₁ = ∅
        assembly {
            // Set the queue to the free pointer
            ptr := mload(fp)
            // Note that Solidity generated IR code reserves memory offset ``0x60`` as well, but a pure Yul object is free to use memory as it chooses.
            if iszero(ptr) { ptr := 0x60 }
            mstore(fp, add(ptr, fp))
            // One word is reserved here to act as a header for the queue,
            // to check if a range is already in the queue.
            head := add(ptr, word)
            tail := head
        }
    }

    function enqueue_range(bytes32 ptr, bytes32 head, bytes32 tail, uint256 j, Node storage range)
        internal
        returns (bytes32 nextTail)
    {
        uint256 flags;
        assembly {
            flags := mload(ptr)
        }
        console.log(flags);
        assembly {
            // Check if the bit j is set in the header
            // The smallest current value of j is 1, corresponding to the half open range
            // [1, 2). The reserved word at the front of the queue correspondingly does not
            // make use of the 0th bit.
            // if the bitwise AND of the the header and 1 shifted to the jth bit is zero, the
            // range is already in the queue.
            if eq(and(mload(ptr), shl(j, 1)), 0) {
                // If it's not, add the range to the queue
                // Set the bit j
                mstore(ptr, or(shl(j, 1), mload(ptr)))
                // Store the range in the queue
                mstore(tail, range.slot)
                // Update the tail of the queue
                nextTail := add(tail, word)
            }
            if eq(nextTail, 0) { nextTail := tail }
        }
    }

    function insert_element(Forest storage forest, uint256 index, uint256 newWeight) external {
        // TODO revert if element already exists
        update_element(forest, index, newWeight);
    }

    // TODO(can this take a list of elements?)
    // TODO b-factor
    // TODO: can one enqueue 2 levels above or does this mess up the ordering
    // Update an element's weight in the forest of trees
    function update_element(Forest storage forest, uint256 index, uint256 newWeight) public {
        // Set up an in memory queue object
        (bytes32 ptr, bytes32 head, bytes32 tail) = new_queue();
        _update_element(forest, index, newWeight, ptr, head, tail)        ;
        update_levels(forest, ptr, head, tail);
    }

    function _update_element(
        Forest storage forest,
        uint256 index,
        uint256 newWeight,
        bytes32 ptr,
        bytes32 head,
        bytes32 tail
    ) internal {
        // TODO revert if weight is same
        Node storage elt = forest.levels[0].ranges[index];

        uint256 oldWeight = elt.weight;

        // update the forest weight
        forest.weight -= oldWeight;
        forest.weight += newWeight;

        // update l0 weight
        forest.levels[0].weight -= oldWeight;
        forest.levels[0].weight += newWeight;

        _update_range(forest, elt, newWeight, 1, ptr, head, tail);
    }

    function _update_range(
        Forest storage forest,
        Node storage range,
        uint256 newWeight,
        uint256 parentLevel,
        bytes32 ptr,
        bytes32 head,
        bytes32 tail
    ) internal {
        // TODO revert if weight is same
        uint256 oldWeight = range.weight;

        // update leaf/element weight
        range.weight = newWeight;

        // get the current range index
        uint256 j = 0;
        if (oldWeight > 0) {
            j = floor_ilog(oldWeight) + 1;
        }
        Node storage currentParent = forest.levels[parentLevel].ranges[j];
        
        // handle current parent, i.e. the parent range index != 0
        if (j != 0) {
            // enqueue the current parent range for update if it's not a zero range
            enqueue_range(ptr, head, tail, j, currentParent);

            // TODO (gas): these ops are effectively reversed in move_range below if
            // the range is being updated
            currentParent.weight += newWeight;
            currentParent.weight -= oldWeight;
        }

        if (j == 0 || newWeight < 2 ** (j - 1) || (2 ** j) <= newWeight) {
            // parent range is changing if
            //  the current parent is a zero range
            //  the updated weight does not belong to the current parent
            uint256 k = floor_ilog(newWeight) + 1;
            Node storage newParent = forest.levels[parentLevel].ranges[k];
            newParent = move_range(forest, range, 0, currentParent, newParent);

            enqueue_range(ptr, head, tail, k, newParent);
        }
    }

    function generate(Forest storage forest, uint256 seed) external view returns (uint256) {
        // level search with the URV by finding the minimum integer l such that
        // U * W < ∑ₖ weight(Tₖ), where 1 ≤ k ≤ l, U == URV ∈ [0, 1), W is the total weight
        // seed ∈ [0, 255), so the arithmetic included is to put it into a fractional value
        uint256 l = 1;
        uint256 w = 0;

        // scale the seed down to 128b, to ensure muldiv doesn't underflow when dividing
        // by intmax
        seed >>= 128;
        uint256 threshold = (forest.weight * seed) / type(uint128).max;
        uint256 j;
        uint256 lj;

        Level storage chosenLevel;

        // TODO: level has no root ranges
        while (w <= threshold) {
            w += forest.levels[l].weight;
            l++;
        }
        w = 0;
        chosenLevel = forest.levels[l];

        mapping(uint256 => Node) storage ranges = chosenLevel.ranges;

        threshold = chosenLevel.weight;
        lj = chosenLevel.roots;

        // select root range within level
        while (w < threshold) {
            j = floor_ilog(lj) + 1;
            lj -= 2 ** j;
            w += ranges[j].weight;
        }

        return bucket_rejection(forest, l, j, seed);
    }

    /**
     * preprocess
     * 
     * update weight of the element and forest
     * update weight of parent range 
     * enqueue update to parent range, 
     * if changing parent, remove edge from parent
     * if changing parent, update weight of new parent range
     * if changing parent, add edge from new parent range
     * if changing parent, enqueue update to new parent range
     * 
     * 
     * insert element
     * revert if element is already nonzero
     * 
     * update element
     * 
     * 
     * TODO 
     * 
     * unify insert elt and update elt
     * 
     * preprocess externalL
     * update element internal
     * process levels
     * 
     * update element external:
     * update element internal 
     * process levels
     * 
     * process levels 
     * agnostic to preprocess or update 
     * we just process the queue
     */

    function bucket_rejection(Forest storage forest, uint256 level, uint256 range, uint256 urv)
        internal
        view
        returns (uint256)
    {
        // We want to choose a child to descend to from the range.
        // To do this, we use the bucket rejection method as described by
        // Knuth.

        // Here we expand numbers from the URV
        uint256 i = 1;
        bool repeat = true;
        Node storage range_s = forest.levels[level].ranges[range];
        uint256 n = range_s.children.length;
        uint256 index;
        uint256 ilog_n = floor_ilog(n);
        uint256 scale_down_bits = 255 - ilog_n;
        while (repeat) {
            uint256 expanded_urv = uint256(keccak256(abi.encode(urv, i++))) >> scale_down_bits;
            uint256 un = expanded_urv * n;
            // = ⌊un⌋
            index = ((expanded_urv * n) >> ilog_n) << ilog_n;
            if (
                (un - index)
                    > (forest.levels[range_s.children[index].level].ranges[range_s.children[index].index].weight << ilog_n)
            ) {
                repeat = false;
            }
        }
        return ((index >> ilog_n) + 1);
    }

    function is_root_range(Node storage range, Level storage level) internal view returns (bool) {
        return (level.roots & (2 ** range.index)) != 0;
    }

    /*=================== MATH ===================*/

    // TODO: There may be a slightly more optimal implementation of this in Hackers delight.
    // https://github.com/hcs0/Hackers-Delight/blob/master/nlz.c.txt
    // @return the number of leading zeros in the binary representation of x
    function nlz(uint256 x) public pure returns (uint256) {
        if (x == 0) {
            return 256;
        }

        uint256 n = 1;

        if (x >> 128 == 0) {
            n += 128;
            x <<= 128;
        }
        if (x >> 192 == 0) {
            n += 64;
            x <<= 64;
        }
        if (x >> 224 == 0) {
            n += 32;
            x <<= 32;
        }
        if (x >> 240 == 0) {
            n += 16;
            x <<= 16;
        }
        if (x >> 248 == 0) {
            n += 8;
            x <<= 8;
        }
        if (x >> 252 == 0) {
            n += 4;
            x <<= 4;
        }
        if (x >> 254 == 0) {
            n += 2;
            x <<= 2;
        }

        n -= x >> 255;

        return n;
    }

    // @retrun integer ⌊lg n⌋ of x.
    function floor_ilog(uint256 x) public pure returns (uint256) {
        return (255 - nlz(x));
    }
}
