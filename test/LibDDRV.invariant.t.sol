// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {Math} from "./utils/Math.sol";
import {LibDDRVUtils} from "./utils/LibDDRVUtils.sol";

import {ContractUnderTest} from "./utils/ContractUnderTest.sol";
import {Handler} from "./utils/Handler.sol";

// TEMP Unicode symbols for reference
// Rⱼ⁽ℓ⁾
// Rⱼʹ⁽ℓ⁾
// Rⱼʹ⁽ℓ⁺¹⁾
// 2ʲʹ
// 2ʲʹ⁻¹
// reg: jʹ
// sub: ⱼʹ
// super: ʲʹ
// ᵐ⁻¹⁺ᶜ
// ℓ

/// @notice Invariant tests for LibDDRV
/// For more info, see https://kuscholarworks.ku.edu/bitstream/handle/1808/7224/MVN03.dynamic_rv_gen.pdf
contract LibDDRVInvariantTest is Test {
    ContractUnderTest internal c;
    Handler internal handler;

    function setUp() public {
        c = new ContractUnderTest();
        handler = new Handler(address(c));

        excludeContract(address(c));
    }

    /**
     * @dev Invariant A -- "Number of levels"
     *
     * The total number of levels L in the forest of trees is <= lg* N + 1 (where lg* denotes the
     * base-2 iterated logarithm; for more info, see https://en.wikipedia.org/wiki/Iterated_logarithm).
     *
     * (from Theorem 4)
     */
    function invariantA_numberOfLevels() public {
        assertLe(c.numberOfLevels(), Math.logStar2(c.numberOfLevels()) + 1, "Number of levels");
    }

    /**
     * @dev Invariant B -- "Number of non-empty ranges"
     *
     * The number of non-empty ranges is O(N), i.e., it is of the same order as the number of elements N.
     *
     * (from Lemma 4)
     */
    function invariantB_numberOfNonEmptyRanges() public {
        assertEq(
            Math.floor(Math.log10(c.numberOfRanges())),
            Math.floor(Math.log10(c.numberOfElements())),
            "Number of non-empty ranges"
        );
    }

    /**
     * @dev Invariant C -- "Parent range of non-root ranges"
     *
     * For any non-root range Rⱼ⁽ℓ⁾ (defined as having degree m >= 2, where 2 is the degree bound constant),
     * its parent range is Rⱼʹ⁽ℓ⁺¹⁾ and its weight is within [2ʲʹ⁻¹, 2ʲʹ), where jʹ is the range number of
     * its weight.
     *
     * (from Lemma 1)
     */
    function invariantC_parentRangeOfNonRootRanges() public {
        // Loop through all non-root ranges.

        // Check that its parent range is Rⱼʹ⁽ℓ⁺¹⁾.

        // Check that its weight is within [2ʲʹ⁻¹, 2ʲʹ).

        assertTrue(false, "Parent range of non-root ranges"); // TEMP
    }

    /**
     * @dev Invariant D -- "Difference between range number of children and of non-root range itself"
     *
     * For any non-root range Rⱼ⁽ℓ⁾ with degree m >= 2, the difference between the range number of its
     * children jʹ and its own range number j satisfies the inequality lg m - 1 < jʹ - j < lg m + 1.
     *
     * (from Lemma 1)
     */
    function invariantD_differenceBetweenRangeNumberOfChildrenAndNonRootRangeItself() public {
        // Loop through all non-root ranges.

        // Calculate the difference between the range number of its children jʹ and its own range number j.

        // Check that it satisfies the inequality lg m - 1 < jʹ - j < lg m + 1.

        assertTrue(false, "Difference between range number of children and of non-root range itself"); // TEMP
    }

    /**
     * @dev Invariant E -- "Degree of one child of non-root ranges on level 2+"
     *
     * // QUESTION clarify if is this one child and one child only, or at least one child?
     *
     * For any non-root range Rⱼ⁽ℓ⁾ with degree m >= 2 on level 2 or higher, one of its children has
     * degree >= 2ᵐ⁻¹ + 1.
     *
     * (from Lemma 2)
     */
    function invariantE_degreeOfOneChildOfNonRootRangesOnLevel2AndUp() public {
        // Loop through all levels 2 and up.

        // Loop through all non-root ranges on this level.

        // Check that one of its children has degree >= 2ᵐ⁻¹ + 1.

        assertTrue(false, "Degree of one child of non-root ranges on level 2+"); // TEMP
    }

    /**
     * @dev Invariant F -- "Number of grandchildren of non-root ranges on level 2+"
     *
     * For any non-root range Rⱼ⁽ℓ⁾ with degree m >= 2 on level 2 or higher, the number of its grandchildren
     * is >= 2ᵐ + m - 1.
     *
     * (from Lemma 2)
     */
    function invariantF_numberOfGrandchildrenOfNonRootRangesOnLevel2AndUp() public {
        // Loop through all levels 2 and up.

        // Loop through all non-root ranges on this level.

        // Check that the number of its grandchildren is >= 2ᵐ + m - 1.

        assertTrue(false, "Number of grandchildren of non-root ranges on level 2+"); // TEMP
    }

    /**
     * @dev Invariant G -- "Difference between range numbers of smallest-numbered descendents of
     * non-root ranges on level 3+"
     *
     * // QUESTION what precisely is smallest-numbered range? —- think smallest index but could be smallest weight / range number
     *
     * For any non-root range Rⱼ⁽ℓ⁾ with degree m >= 2 where level ℓ >= k >= 3, the range number of
     * the smallest-numbered descendent range on level ℓ-k minus the range number of the smallest-numbered
     * descendent range on level ℓ-k+1 is greater than the base-2 power tower of order k and hat m (e.g.,
     * the base-2 power tower of order 3 and hat 7 is 2^2^2^7, for order 4 it is 2^2^2^2^7, and so on;
     * for more info, see https://mathworld.wolfram.com/PowerTower.html).
     *
     * (from Lemma 3)
     */
    function invariantG_differenceBetweenRangeNumbersOfSmallestNumberedDescendentsOfNonRootRangesOnLevel3AndUp()
        public
    {
        // Loop through all levels 3 and up.

        // Loop through this level and any levels above it.

        // Get the smallest-numbered descendent range on level ℓ-k.

        // Get the smallest-numbered descendent range on level ℓ-k+1.

        // Calculate the base-2 power tower of order k and hat m.

        // Check that the difference between them is greater than this value.

        assertTrue(
            false,
            "Difference between range numbers of smallest-numbered descendents of non-root ranges on level 3+" // TEMP
        );
    }

    /**
     * @dev Invariant H -- "Number of descendents of non-root ranges on level 3+"
     *
     * For any non-root range Rⱼ⁽ℓ⁾ with degree m >= 2 where level ℓ >= k >= 3, the number of descendents
     * on level ℓ-k > the base-2 power tower of order k and hat m (see Invariant E for power tower examples).
     *
     * (from Lemma 3)
     */
    function invariantH_numberOfDescendentsOfNonRootRangesOnLevel3AndUp() public {
        // Loop through all levels 3 and up.

        // Loop through this level and any levels above it.

        // Get the number of descendents on level ℓ-k.

        // Calculate the base-2 power tower of order k and hat m.

        // Check that the number of descendents on level ℓ-k is greater than this value.

        assertTrue(false, "Number of descendents of non-root ranges on level 3+"); // TEMP
    }

    /*//////////////////////////////////////////////////////////////
    //  Modified Data Structure and Algorithm
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Invariant A -- "Number of levels"
     *
     * The total number of levels L in the forest of trees is <= lg* N - 1 (where lg* denotes the
     * base-2 iterated logarithm; for more info, see https://en.wikipedia.org/wiki/Iterated_logarithm).
     *
     * (from Theorem 4ʹ)
     */
    function MODIFIED_invariantA_numberOfLevels() public {
        assertLe(c.numberOfLevels(), Math.logStar2(c.numberOfLevels()) - 1, "Number of levels");
    }

    // NOTE There would be no change in MODIFIED data structure for invariant B

    /**
     * @dev Invariant C -- "Parent range of non-root ranges"
     *
     * For any non-root range Rⱼ⁽ℓ⁾ (defined as having degree m >= d, where d is the degree bound
     * constant), its parent range is Rⱼʹ⁽ℓ⁺¹⁾ and its weight is within [2ʲʹ⁻¹, 2ʲʹ),
     * where jʹ is the range number of its weight.
     *
     * (from Lemma 1ʹ)
     */
    function MODIFIED_invariantC_parentRangeOfNonRootRanges() public {
        // Loop through all non-root ranges.

        // Check that its parent range is Rⱼʹ⁽ℓ⁺¹⁾.

        // Check that its weight is within [2ʲʹ⁻¹, 2ʲʹ).

        assertTrue(false, "Parent range of non-root ranges"); // TEMP
    }

    /**
     * @dev Invariant D -- "Difference between range number of children and of non-root range itself"
     *
     * For any non-root range Rⱼ⁽ℓ⁾ with degree m >= d, the difference between the range number of its children jʹ and its own range number j
     * satisfies the inequality lg m - lg (2+b)/(1-b) < jʹ - j < lg m + lg (2+b)/(1-b).
     *
     * (from Lemma 1ʹ)
     */
    function MODIFIED_invariantD_differenceBetweenRangeNumberOfChildrenAndNonRootRangeItself() public {
        // Loop through all non-root ranges.

        // Calculate the difference between the range number of its children jʹ and its own range number j.

        // Check that it satisfies the inequality lg m - lg (2+b)/(1-b) < jʹ - j < lg m + lg (2+b)/(1-b).

        assertTrue(false, "Difference between range number of children and of non-root range itself");
    }

    /**
     * @dev Invariant E -- "Degree of one child of non-root ranges on level 2+"
     *
     * // QUESTION clarify if is this one child and one child only, or at least one child?
     *
     * For any non-root range Rⱼ⁽ℓ⁾ with degree m >= d on level 2 or higher, one of its children has degree >= 2ᵐ⁻¹⁺ᶜ, where c is a
     * non-negative integer constant >= 1 used to calculate the degree bound constant.
     *
     * (from Lemma 2ʹ)
     */
    function MODIFIED_invariantE_degreeOfOneChildOfNonRootRangesOnLevel2AndUp() public {
        // Loop through all levels 2 and up.

        // Loop through all non-root ranges on this level.

        // Check that one of its children has degree >= 2ᵐ⁻¹⁺ᶜ.

        assertTrue(false, "Degree of one child of non-root ranges on level 2+"); // TEMP
    }

    /**
     * @dev Invariant F -- "Number of grandchildren of non-root ranges on level 2+"
     *
     * For any non-root range Rⱼ⁽ℓ⁾ with degree m >= d on level 2 or higher, the number of its grandchildren is >= 2ᵐ⁺ᶜ + m - 2ᶜ, where
     * c is a non-negative integer constant >= 1 used to calculate the degree bound constant.
     *
     * (from Lemma 2ʹ)
     */
    function MODIFIED_invariantF_numberOfGrandchildrenOfNonRootRangesOnLevel2AndUp() public {
        // Loop through all levels 2 and up.

        // Loop through all non-root ranges on this level.

        // Check that the number of its grandchildren is >= 2ᵐ⁺ᶜ + m - 2ᶜ.

        assertTrue(false, "Number of grandchildren of non-root ranges on level 2+"); // TEMP
    }

    /**
     * @dev Invariant G -- "Difference between range numbers of smallest-numbered descendents of non-root ranges on level 3+"
     *
     * // QUESTION what precisely is smallest-numbered range? —- think smallest index but could be smallest weight / range number
     *
     * For any non-root range Rⱼ⁽ℓ⁾ with degree m >= d where level ℓ >= k >= 3, the range number of the smallest-numbered descendent range
     * on level ℓ-k minus the range number of the smallest-numbered descendent range on level ℓ-k+1
     * is greater than or equal to the base-2 power tower of order k and hat m (e.g., the base-2 power tower of
     * order 3 and hat 7 is 2^2^2^7, for order 4 it is 2^2^2^2^7, and so on; for more info, see
     * https://mathworld.wolfram.com/PowerTower.html) plus lg (2+b)/(1-b) + 1.
     *
     * (from Lemma 3ʹ)
     */
    function MODIFIED_invariantG_differenceBetweenRangeNumbersOfSmallestNumberedDescendentsOfNonRootRangesOnLevel3AndUp(
    ) public {
        // Loop through all levels 3 and up.

        // Loop through this level and any levels above it.

        // Get the smallest-numbered descendent range on level ℓ-k.

        // Get the smallest-numbered descendent range on level ℓ-k+1.

        // Calculate the base-2 power tower of order k and hat m + lg (2+b)/(1-b) + 1.

        // Check that the difference between them is greater than this value + lg (2+b)/(1-b) + 1.

        assertTrue(
            false,
            "Difference between range numbers of smallest-numbered descendents of non-root ranges on level 3+" // TEMP
        );
    }

    /**
     * @dev Invariant H -- "Number of descendents of non-root ranges on level 3+"
     *
     * For any non-root range Rⱼ⁽ℓ⁾ with degree m >= d where level ℓ >= k >= 3, the number of descendents on level ℓ-k >= the base-2 power
     * tower of order k and hat m (see Invariant E for power tower examples).
     *
     * (from Lemma 3ʹ)
     */
    function MODIFIED_invariantH_numberOfDescendentsOfNonRootRangesOnLevel3AndUp() public {
        // Loop through all levels 3 and up.

        // Loop through this level and any levels above it.

        // Get the number of descendents on level ℓ-k.

        // Calculate the base-2 power tower of order k and hat m.

        // Check that the number of descendents on level ℓ-k is greater than or equal to this value.

        assertTrue(false, "Number of descendents of non-root ranges on level 3+"); // TEMP
    }
}
