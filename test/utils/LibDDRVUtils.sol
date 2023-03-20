// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Math} from "./Math.sol";

/// TODO
library LibDDRVUtils {
    /// TODO
    function calculateRangeNumber(uint256 weight) public pure returns (uint256 rangeNumber) {
        rangeNumber = Math.floor(Math.log2(weight)) + 1;
    }

    /// TODO
    function calculateToleranceBounds(uint256 b, uint256 j)
        public
        pure
        returns (uint256 toleranceLowerBound, uint256 toleranceUpperBound)
    {
        toleranceLowerBound = (1 - b) * (2 ** (j - 1));
        toleranceUpperBound = (2 + b) * (2 ** (j - 1));
    }

    /// TODO
    function calculateDegreeBound(uint256 b, uint256 c) public pure returns (uint256 d) {
        d = (((1 - b) / (2 + b)) ** 2 * 2 ** c) / 2;
    }

    /// TODO
    function isElementOfHalfOpenRange(uint256 x, uint256 lowerBound, uint256 upperBound)
        public
        pure
        returns (bool within)
    {
        within = (x >= lowerBound && x < upperBound);
    }
}
