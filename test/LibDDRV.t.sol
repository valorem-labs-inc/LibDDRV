// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

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

    function testPreprocess() public {
        uint256 countHeads = 0;
        uint256 countTails = 0;
        uint256[] memory weights = new uint256[](2);
        weights[0] = 50;
        weights[1] = 50;

        LibDDRV.preprocess(weights, forest);

        // total weight should be the sum
        assertEq(forest.weight, 100);

        // level 0 (i.e. the leaves) should not be initialized
        assertEq(forest.levels[0].weight, 0);
        assertEq(forest.levels[0].roots, 0);

        // two elements should be in the only range on level 1
        assertEq(forest.levels[1].weight, 100);

        // emit
        emit log_named_uint("lvl1 roots", forest.levels[1].roots);
    }

    function testUpdate() public {
        uint256 countHeads = 0;
        uint256 countTails = 0;
        uint256[] memory weights = new uint256[](2);
        weights[0] = 50;
        weights[1] = 50;

        LibDDRV.preprocess(weights, forest);
        LibDDRV.update_element(0, 30, forest);
        assertEq(forest.levels[0].ranges[0].weight, 30);
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
