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
    // Get/Generate a uniform random variate
    // TODO(does this need have a specified source of randomness?
    function generate_urv(uint8 precision) internal {

    }

    // Construct a level in the forest of trees
    function construct_level() internal {

    }

    // Reject buckets which don't match criterion
    function bucket_rejection() internal {

    }

    function insert_bucket(uint256 i, Range storage range) internal {

    }

    // TODO: There may be a slightly more optimal implementation of this in Hackers delight.
    // @return the number of leading zeros in the binary representation of x
    function nlz(uint256 x) internal pure returns (uint256) {
        if (x == 0) {
            return 256;
        }

        uint256 n = 1;

        if (x >> 128 == 0) { n += 128; x <<= 128; }
        if (x >> 192 == 0) { n += 64; x <<= 64; }
        if (x >> 224 == 0) { n += 32; x <<= 32; }
        if (x >> 240 == 0) { n += 16; x <<= 16; }
        if (x >> 248 == 0) { n += 8; x <<= 8; }
        if (x >> 252 == 0) { n += 4; x <<= 4; }
        if (x >> 254 == 0) { n += 2; x <<= 2; }

        n -= x >> 255;

        return n;
    }

    function floor_ilog(uint256 x) internal pure returns (uint256) {
        return (255 - nlz(x));
    }

    // Preprocess an array of elements and their weights into a forest of trees.
    // TODO(This presently supports natural number weights, could easily support posits)
    function preprocess(uint256[] memory weights, mapping(uint256 => mapping(uint256 => Range)) storage forest) external {
        uint256 l = 1;
        // Set up an in memory queue object
        bytes32 ptr;
        bytes32 tail;
        assembly {
            // Set the queue to the free pointer
            ptr := mload(0x40)
            tail := ptr
        }
        uint256 n = weights.length;
        uint256 i;
        uint256 j;
        for (i=1; i <= n; i++) {
            j = floor_ilog(weights[i]) + i;
            Range storage range = forest[l][j];
            insert_bucket(i, range);
            // If r[l, j] not in q, then enqueue
            assembly {
                // TODO(Check if the range is already in the queue)
                mstore(tail, range.slot)
                tail := add(tail, 0x20)
            }
        }
    }

    // TODO(can this take a list of elements?)
    // Update an element's weight in the forest of trees
    function update_element() external {}

    // Generate a discretely weighted random variate
    function generate() external {

    }
}
