// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {Math} from "./utils/Math.sol";
import {LibDDRVUtils} from "./utils/LibDDRVUtils.sol";

contract World {
    uint256 public N;
    uint256 public L;
    uint256 public R;
    // Element[] public elements;
    // mapping (uint256 => mapping (uint256 => Range)) public forest; // forest[level][rangeNumber]
    // uint256[] public rangeWeights;
    // uint256[] public levelWeights;

    constructor(uint256 numberOfElements, uint256 numberOfLevels, uint256 numberOfRanges) {
        N = numberOfElements;
        L = numberOfLevels;
        R = numberOfRanges;
    }
}

/// @notice Invariant tests for LibDDRV
/// For more info, see https://kuscholarworks.ku.edu/bitstream/handle/1808/7224/MVN03.dynamic_rv_gen.pdf
contract LibDDRVInvariantTest is Test {
    World internal world;

    function setUp() public {
        world = new World(11, 2, 9);
    }

    /**
     * @dev Invariant A1 -- "Maximum number of levels"
     *
     * The total number of levels L in the forest of trees is <= lg* N - 1 (where lg* denotes the
     * base-2 iterated logarithm; for more info, see https://en.wikipedia.org/wiki/Iterated_logarithm).
     */
    function invariantA1_maximumNumberOfLevels() public {
        assertLe(world.L(), Math.logStar2(world.L()) - 1, "Maximum number of levels");
    }

    /**
     * @dev Invariant A2 -- "Number of non-empty ranges"
     *
     * // TODO how to accurately assert the value is on the order of N ?
     *
     * The number of non-empty ranges is O(N).
     */
    function invariantA2_numberOfNonEmptyRanges() public {
        assertLe(world.R(), world.N(), "Number of non-empty ranges");
    }

    /**
     * @dev Invariant B1 -- "Parent range of non-root ranges"
     *
     * For any non-root range R_j_(l) (defined as having degree m >= d, where d is the degree bound
     * constant), its parent range is R_j'_(l+1) and its weight is within [2^(j'-1), 2^(j')),
     * where j' is the range number of its weight.
     */
    function invariantB1_parentRangeOfNonRootRanges() public {
        assertTrue(false, "Parent range of non-root ranges");
    }

    /**
     * @dev Invariant B2 -- "Difference between range number of children and of non-root range itself"
     *
     * For any non-root range R_j_(l) (defined as having degree m >= d, where d is the degree bound
     * constant), the difference between the range number of its children j' and its own range number j
     * satisfies the inequality lg m - lg (2+b)/(1-b) < j' - j < lg m + lg (2+b)/(1-b).
     */
    function invariantB2_differenceBetweenRangeNumberOfChildrenAndNonRootRangeItself() public {
        assertTrue(false, "Difference between range number of children and of non-root range itself");
    }

    /**
     * @dev Invariant B3 -- "Degree of one child of non-root ranges on level 2+"
     *
     * // TODO clarify if is this one child and one child only, or at least one child (from Lemma 2')
     *
     * For any non-root range R_j_(l) (defined as having degree m >= d, where d is the degree bound
     * constant) on level 2 or higher, one of its children has degree >= 2^(m-1+c), where c is a
     * non-negative integer constant >= 1 used to calculate the degree bound constant.
     */
    function invariantB3_degreeOfOneChildOfNonRootRangesOnLevel2AndUp() public {
        assertTrue(false, "Degree of one child of non-root ranges on level 2+");
    }

    /**
     * @dev Invariant B4 -- "Number of grandchildren of non-root ranges on level 2+"
     *
     * For any non-root range R_j_(l) (defined as having degree m >= d, where d is the degree bound
     * constant) on level 2 or higher, the number of its grandchildren is >= 2^(m+c) - 2^c + m, where
     * c is a non-negative integer constant >= 1 used to calculate the degree bound constant.
     */
    function invariantB4_numberOfGrandchildrenOfNonRootRangesOnLevel2AndUp() public {
        assertTrue(false, "Number of grandchildren of non-root ranges on level 2+");
    }

    /**
     * @dev Invariant B5 -- "Difference between range numbers of smallest-numbered descendents of non-root ranges on level 3+"
     *
     * // TODO what precisely is smallest-numbered range? —- think smallest index but could be smallest weight / range number
     *
     * For any non-root range R_j_(l) (defined as having degree m >= d, where d is the degree bound
     * constant) where level l >= k >= 3, the range number of the smallest-numbered descendent range
     * on level l-k minus the range number of the smallest-numbered descendent range on level l-k+1
     * is greater than the base-2 power tower of order k and hat m (e.g., the base-2 power tower of
     * order 3 and hat 7 is 2^2^2^7, for order 4 it is 2^2^2^2^7, and so on; for more info, see
     * https://mathworld.wolfram.com/PowerTower.html).
     */
    function invariantB5_differenceBetweenRangeNumbersOfSmallestNumberedDescendentsOfNonRootRangesOnLevel3AndUp()
        public
    {
        assertTrue(
            false, "Difference between range numbers of smallest-numbered descendents of non-root ranges on level 3+"
        );
    }

    /**
     * @dev Invariant B6 -- "Number of descendents of non-root ranges on level 3+"
     *
     * For any non-root range R_j_(l) (defined as having degree m >= d, where d is the degree bound
     * constant) where level l >= k >= 3, the number of descendents on level l-k > the base-2 power
     * tower of order k and hat m (see Invariant E for power tower examples).
     */
    function invariantB6_numberOfDescendentsOfNonRootRangesOnLevel3AndUp() public {
        assertTrue(false, "Number of descendents of non-root ranges on level 3+");
    }
}
