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

struct Range {
    uint256 j;
}

library LibDDRV {
    // Construct a level in the forest of trees
    function construct_level() internal {}

    // Reject buckets which don't match criterion
    function bucket_rejection() internal {}

    function insert_bucket(uint256 i, Range storage range) internal {}

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

    // Preprocess an array of elements and their weights into a forest of trees.
    // TODO(This presently supports natural number weights, could easily support posits)
    function preprocess(uint256[] memory weights, mapping(uint256 => mapping(uint256 => Range)) storage forest)
        external
    {
        uint256 l = 1;
        // Set up an in memory queue object
        bytes32 ptr;
        uint256 in_queue;
        bytes32 tail;
        assembly {
            // Set the queue to the free pointer
            ptr := mload(0x40)
            // One word is reserved here to act as a header for the queue,
            // to check if a range is already in the queue.
            tail := add(ptr, 0x20)
        }
        uint256 n = weights.length;
        uint256 i;
        uint256 j;
        for (i = 1; i <= n; i++) {
            j = floor_ilog(weights[i]) + i;
            Range storage range = forest[l][j];
            insert_bucket(i, range);
            // If r[l, j] not in q, then enqueue
            assembly {
                // Check if the bit j is set in the header
                in_queue := shr(255, shl(sub(255, j), mload(ptr)))
                // If it's not, add the range to the queue
                if gt(shr(255, shl(sub(255, j), mload(ptr))), 0) {
                    // Set the bit j
                    // Store the range in the queue
                    mstore(tail, range.slot)
                    // Update the tail of the queue
                    tail := add(tail, 0x20)
                }
            }
        }
    }

    // TODO(can this take a list of elements?)
    // Update an element's weight in the forest of trees
    function update_element() external {}

    // Generate a discretely weighted random variate given a uniform random
    // and a preprocessed forest of trees.
    function generate(mapping(uint256 => mapping(uint256 => Range)) storage forest, uint256 urv) external {}
}
