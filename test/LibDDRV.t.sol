// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "src/LibDDRV.sol";

contract TestDDRV is Test {
    Forest internal forest;
    uint256[] internal seeds;
    uint256 SEED_COUNT = 1000;

    function setUp() public {
        seeds.push(uint256(keccak256(abi.encode(0))));
        for (uint256 i = 1; i < SEED_COUNT; i++) {
            seeds.push(uint256(keccak256(abi.encode(seeds[i - 1] + i))));
        }
    }

    /*======================== UTILS ========================*/
    function logForest(Forest storage f) internal view {
        console.log("forest weight: %s", f.weight);
        for (uint256 level = 0; level < 10; level++) {
            if (f.levels[level].weight == 0) {
                continue;
            }
            console.log("\t level %s weight: %s", level, f.levels[level].weight);
            console.log("\t level %s roots: %s", level, f.levels[level].roots);
            for (uint256 index = 0; index < 10; index++) {
                if (f.levels[level].ranges[index].weight == 0) {
                    continue;
                }
                console.log("\t\t level %s index %s weight: %s", level, index, f.levels[level].ranges[index].weight);
                console.log(
                    "\t\t level %s index %s children: %s", level, index, f.levels[level].ranges[index].children.length
                );
            }
        }
    }

    /*======================== TESTS ========================*/

    function testPreprocess_simple() public {
        uint256[] memory weights = new uint256[](2);
        weights[0] = 50;
        weights[1] = 50;

        LibDDRV.preprocess(weights, forest);

        // total weight should be the sum
        assertEq(forest.weight, 100);

        // The two weights should exist as leaves on level 0
        assertEq(forest.levels[0].ranges[0].weight, 50);
        assertEq(forest.levels[0].ranges[1].weight, 50);

        logForest(forest);

        // two elements should be in the only range on level 1
        assertEq(forest.levels[0].weight, 100);
    }

    function testPreprocess_overflow() public {
        uint256[] memory weights = new uint256[](4);
        uint256 expectedWeight = 22; //E i [4,7]
        weights[0] = 4;
        weights[1] = 5;
        weights[0] = 6;
        weights[1] = 7;

        LibDDRV.preprocess(weights, forest);

        // total weight should be the sum
        assertEq(forest.weight, expectedWeight);
        assertEq(forest.levels[0].weight, expectedWeight);

        assertEq(forest.levels[1].weight, expectedWeight);

        uint256 l1RangeIndex = LibDDRV.floor_ilog(7);
        uint256 l2RangeIndex = LibDDRV.floor_ilog(expectedWeight);

        console.log("l1 index %s", l1RangeIndex);
        console.log("l2 index %s", l2RangeIndex);

        // range weighs 22, and is not a root range
        assertEq(forest.levels[1].ranges[l1RangeIndex].weight, expectedWeight);
        assertEq(forest.levels[1].roots, 0);

        // range weighs 22, and is the only root range
        assertEq(forest.levels[2].ranges[l2RangeIndex].weight, expectedWeight);
        assertEq(forest.levels[2].roots, l2RangeIndex);
    }

    // Test that the forest is built correctly when there are more 4 elements
    function testPreprocess_threeLevels() public {
        uint256[] memory weights = new uint256[](4);
        uint256 expectedWeight = 22; //E i [4,7]
        weights[0] = 4;
        weights[1] = 5;
        weights[2] = 6;
        weights[3] = 7;

        LibDDRV.preprocess(weights, forest);

        // total weight should be the sum
        assertEq(forest.weight, expectedWeight);
        assertEq(forest.levels[0].weight, expectedWeight);
        console.log("assert l1 weight");
        // Should be zero, since we only add weight for root ranges
        assertEq(forest.levels[1].weight, 0);

        uint256 l1RangeIndex = LibDDRV.floor_ilog(7) + 1;
        uint256 l2RangeIndex = LibDDRV.floor_ilog(expectedWeight) + 1;

        console.log("l1 index %s", l1RangeIndex);
        console.log("l2 index %s", l2RangeIndex);

        // range weighs 22, and is not a root range
        console.log("assert l1 index range weight");
        assertEq(forest.levels[1].ranges[l1RangeIndex].weight, 22);
        assertEq(forest.levels[1].roots, 0);

        // range weighs 22, and is the only root range
        console.log("assert l2 index range weight");
        assertEq(forest.levels[2].ranges[l2RangeIndex].weight, expectedWeight);
        assertEq(forest.levels[2].roots, l2RangeIndex);
    }

    function testUpdate_simple() public {
        uint256[] memory weights = new uint256[](2);
        weights[0] = 50;
        weights[1] = 50;

        LibDDRV.preprocess(weights, forest);
        LibDDRV.update_element(0, 30, forest);
        assertEq(forest.levels[0].ranges[0].weight, 30);
    }

    function testGenerate_simple() public {
        uint256[] memory weights = new uint256[](2);
        weights[0] = 50;
        weights[1] = 50;

        LibDDRV.preprocess(weights, forest);
        uint256 element = LibDDRV.generate(forest, 0);
        assertTrue(element == 0 || element == 1);
    }

    function testGenerate() public {
        uint256 countHeads = 0;
        uint256 countTails = 0;
        uint256[] memory weights = new uint256[](2);
        weights[0] = 50;
        weights[1] = 50;

        LibDDRV.preprocess(weights, forest);

        // flip 1000 coins
        for (uint256 i = 0; i < SEED_COUNT; i++) {
            uint256 seed = seeds[i];
            uint256 element = 0;
            // TODO(What is causing forge to hang on generate?)
            element = LibDDRV.generate(forest, seed);

            if (element == 0) {
                countTails++;
            } else if (element == 1) {
                countHeads++;
            } else {
                revert("unexpected element index returned from generate");
            }
        }

        // assert these after
        emit log_named_uint("heads count:", countHeads);
        emit log_named_uint("tails count:", countTails);
    }
}
