// SPDX-License-Identifier: MIT

/*
 * Library for generating dynamically weighted discrete probability mass function
 * random variates.
 *
 * Copyright © 2023 Valorem Labs Inc.
 *
 * Author: 0xAlcibiades <alcibiades@valorem.xyz>
 */

pragma solidity >=0.8.8;

// @notice An element that can be selected from many, with likelihood
/// of selection dictated by its weight.
struct Element {
    uint256 index;
    uint256 weight;
}

struct Range {
    uint256 weight;
    Element[] elements;
}

struct Level {
    uint256 weight;
    uint256 roots;
    mapping(uint256 => Range) ranges;
}

struct Forest {
    uint256 weight;
    mapping(uint256 => Level) levels;
}

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

    function floor_ilog(uint256 x) internal pure returns (uint256) {
        return (255 - nlz(x));
    }

    // One issue here, is that each iteration expects a new URV
    function bucket_rejection() internal {}

    function insert_bucket(uint256 i, Range storage range) internal {}

    function delete_range(Range storage range) internal {}

    // Construct a level in the forest of trees
    function construct_level(Forest storage forest, uint256 level, bytes32 ptr, bytes32 head, bytes32 tail)
        internal
        returns (bytes32 ptr1, bytes32 head1, bytes32 tail1)
    {
        // Setup an empty level
        forest.levels[level].weight = 0;
        forest.levels[level].roots = 0;
        // Setup an empty queue
        // Qₗ₊₁ = ∅
        assembly {
            // Set the queue to the free pointer
            ptr1 := mload(fp)
            head1 := add(ptr, word)
            // One word is reserved here to act as a header for the queue,
            // to check if a range is already in the queue.
            tail1 := head
        }
        // While Qₗ ≠ ∅
        while (head != tail) {
            // Dequeue range from storage
            Range storage range;
            assembly {
                range.slot := mload(tail)
                tail := sub(word, tail)
            }
            // Get weight and range number
            uint256 weight = range.weight;
            uint256 j = floor_ilog(weight) + 1;
            // TODO(Support expanded degree bound)
            if (range.elements.length > 2) {
                Range storage new_range = forest.levels[level].ranges[j];
                assembly {
                    // Check if the bit j is set in the header
                    if gt(shr(255, shl(sub(255, j), mload(ptr1))), 0) {
                        // If it's not, add the range to the queue
                        // Set the bit j
                        mstore(ptr1, or(shl(j, 1), mload(ptr1)))
                        // Store the range in the queue
                        mstore(tail1, new_range.slot)
                        // Update the tail of the queue
                        tail := add(tail1, word)
                    }
                }
                insert_bucket(j, new_range);
                delete_range(range);
            } else {
                forest.levels[level].weight += weight;
                forest.levels[level].roots += j;
            }
            assembly {
                // Cap off the level queue by incrementing the free memory pointer
                mstore(fp, add(tail1, word))
            }
        }
    }

    // Preprocess an array of elements and their weights into a forest of trees.
    // TODO(This presently supports natural number weights, could easily support posits)
    function preprocess(uint256[] memory weights, Forest storage forest) external {
        uint256 l = 1;
        // Set up an in memory queue object
        bytes32 ptr;
        bytes32 head;
        bytes32 tail;
        // Qₗ = ∅
        assembly {
            // Set the queue to the free pointer
            ptr := mload(fp)
            head := add(ptr, word)
            // One word is reserved here to act as a header for the queue,
            // to check if a range is already in the queue.
            tail := head
        }
        uint256 n = weights.length;
        uint256 i;
        uint256 j;
        for (i = 1; i <= n; i++) {
            j = floor_ilog(weights[i]) + 1;
            Range storage range = forest.levels[l].ranges[j];
            insert_bucket(i, range);
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
        // While Qₗ ≠ ∅
        while (head != tail) {
            // Set Qₗ₊₁
            (ptr, head, tail) = construct_level(forest, l, ptr, head, tail);
            // Increment level
            l += 1;
        }
        // The forest is now preprocessed/constructed
    }

    // TODO(can this take a list of elements?)
    // Update an element's weight in the forest of trees
    function update_element() external {}

    // Generate a discretely weighted random variate given a uniform random
    // and a preprocessed forest of trees.
    function generate(mapping(uint256 => mapping(uint256 => Range)) storage forest, uint256 urv) external {}
}
