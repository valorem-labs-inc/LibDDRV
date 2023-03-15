// SPDX-License-Identifier: MIT

/*
 * Library for generating dynamically weighted discrete probability mass function
 * random variates.
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

// A library which takes in weights and uniform random variates and uses them
// to generate dynamically weighted discrete probability mass function random
// variates.
library LibDDRV {
    uint256 private constant fp = 0x40;
    uint256 private constant word = 0x20;

    // TODO: There may be a slightly more optimal implementation of this in Hackers delight.
    // https://github.com/hcs0/Hackers-Delight/blob/master/nlz.c.txt
    // @return the number of leading zeros in the binary representation of x
    function nlz(uint256 x) internal pure returns (uint256) {
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
    function floor_ilog(uint256 x) internal pure returns (uint256) {
        return (255 - nlz(x));
    }

    // One issue here, is that each iteration expects a new URV
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

    // Construct a level in the forest of trees
    function construct_level(Forest storage forest, uint256 level, bytes32 ptr, bytes32 head, bytes32 tail)
        internal
        returns (bytes32 ptr1, bytes32 head1, bytes32 tail1)
    {
        // Setup an empty queue
        (ptr1, head1, tail1) = new_queue();

        // While Qₗ ≠ ∅
        while (head != tail) {
            // Dequeue range from storage
            Node storage range;
            assembly {
                range.slot := mload(tail)
                tail := sub(word, tail)
            }
            // Get weight and range number
            uint256 weight = range.weight;
            uint256 j = floor_ilog(weight) + 1;
            forest.levels[level].weight += weight;
            forest.levels[level].roots += j;
            // TODO(Support expanded degree bound)
            //if (range.children.length > 2) {
            // Then this range moves to the next level
            //Node storage newRange = forest.levels[level].ranges[j];
            //enqueue_range(ptr1, head1, tail1, j, newRange);
            // Insert range from lower level into this level
            // insert_bucket()
            // Delete range from lower level
            //delete_range(range);
            //} else {
            //    forest.levels[level].weight += weight;
            //    forest.levels[level].roots += j;
            //}
            assembly {
                // Cap off the level queue by incrementing the free memory pointer
                mstore(fp, add(tail1, word))
            }
        }
    }

    // Preprocess an array of elements and their weights into a forest of trees.
    // TODO(This presently supports natural number weights, could easily support posits)
    function preprocess(uint256[] calldata weights, Forest storage forest) external {
        // Set up an in memory queue object
        (bytes32 ptr, bytes32 head, bytes32 tail) = new_queue();

        uint256 n = weights.length;
        uint256 i;
        uint256 j;
        for (i = 0; i < n; i++) {
            j = floor_ilog(weights[i]) + 1;
            Node storage range = forest.levels[1].ranges[j];
            // Add this index to table level zero.
            forest.levels[0].ranges[i].weight = weights[i];
            forest.levels[0].ranges[i].index = i;
            // Add this index as a child of the j range on table level one.
            Edge memory edge = Edge({level: 0, index: i});
            forest.levels[1].ranges[j].children.push(edge);
            // Update the forest weight overall
            forest.weight += weights[i];
            // Enqueue the range if it's not already in the queue for the next
            // level.
            enqueue_range(ptr, head, tail, j, range);
        }

        // Construct the forest of trees from the bottom up
        update_levels(ptr, head, tail, forest);
    }

    // TODO(can this take a list of elements?)
    // TODO b-factor
    // Update an element's weight in the forest of trees
    function update_element(uint256 index, uint256 newWeight, Forest storage forest) external {
        uint256 l = 1;
        // Set up an in memory queue object
        (bytes32 ptr, bytes32 head, bytes32 tail) = new_queue();

        Node storage elt = get_element(forest, index);
        uint256 oldWeight = elt.weight;

        // update leaf/element weight
        elt.weight = newWeight;

        // get the current range index
        uint256 j = floor_ilog(oldWeight) + 1;
        Node storage currentRange = forest.levels[1].ranges[j];

        if (newWeight < 2 ** (j - 1) || (2 ** j) <= newWeight) {
            // newWeight does not fall into the same parent range
            // change the parent for this element
            uint256 k = floor_ilog(newWeight) + 1;
            //delete_element(index, currentRange);
            currentRange.weight -= oldWeight;
            Node storage newRange = forest.levels[1].ranges[k];
            //insert_element(index, newRange);
            newRange.weight += newWeight;

            enqueue_range(ptr, head, tail, k, newRange);
        } else {
            // set the new weight of the element
            currentRange.weight += newWeight;
            currentRange.weight -= oldWeight;
        }

        // enqueue the current range for an update
        enqueue_range(ptr, head, tail, j, currentRange);

        update_levels(ptr, head, tail, forest);
    }

    function get_element(Forest storage forest, uint256 index) internal view returns (Node storage) {
        return forest.levels[0].ranges[index];
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
            head := add(fp, word)
            tail := head
        }
    }

    function enqueue_range(bytes32 ptr, bytes32 head, bytes32 tail, uint256 j, Node storage range) internal {
        console.log("Enqueing");
        uint256 flags;
        assembly {
            flags := mload(ptr)
        }
        console.log(flags);
        assembly {
            // Check if the bit j is set in the header
            if gt(shr(255, shl(sub(255, j), mload(ptr))), 0) {
                // If it's not, add the range to the queue
                // Set the bit j
                mstore(ptr, or(shl(j, 1), mload(ptr)))
                // Store the range in the queue
                mstore(tail, range.slot)
                // Update the tail of the queue
                tail := add(tail, word)
            }
            // Cap off the level queue by incrementing the free memory pointer
            mstore(fp, add(tail, word))
        }
    }

    // Propogate upwards any changes in the the element or range weights
    function update_levels(bytes32 ptr, bytes32 head, bytes32 tail, Forest storage forest) internal {
        uint256 l = 1;
        while (head != tail) {
            // Set Qₗ₊₁
            (ptr, head, tail) = construct_level(forest, l, ptr, head, tail);
            // Increment level
            l += 1;
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
}
