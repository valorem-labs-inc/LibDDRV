// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

import "../src/LibDDRV.sol";

contract DDRVMonteCarloTest is Test {
    Forest internal forest;
    uint256[] internal seeds;
    mapping (uint256 => uint256) internal countElementGenerated;

    uint256 internal constant SEED_COUNT = 1000;

    function setUp() public {
        seeds.push(uint256(keccak256(abi.encode(0))));
        for (uint256 i = 1; i < SEED_COUNT; i++) {
            seeds.push(uint256(keccak256(abi.encode(seeds[i - 1] + i))));
        }
    }

    function testMonteCarloSim() public {
        uint256 numElements = 100;
        uint256 numRuns = 10_000;
        uint256 totalWeight = 0;
        uint256[] memory elements = new uint256[](numElements);
        uint256[] memory expectedProbabilities = new uint256[](numElements);
        

        // Preprocess
        // LibDDRV.preprocess(elements, forest);

        // Insert 100 elements
        for (uint256 i = 0; i < numElements; i++) {
            uint256 element = uint256(keccak256(abi.encodePacked(block.number, i))) % 200; // PRN ∈ [0, 199]
            totalWeight += element;
            elements[i] = element;

            // LibDDRV.insert_element(i, element, forest);
        }

        // Calculate approximate expected probabilities
        for (uint256 i = 0; i < numElements; i++) {
            uint256 expectedProbability = FixedPointMathLib.mulDivDown(elements[i], 1e4, totalWeight); // normalize P(x) to 10,000
            expectedProbabilities[i] = expectedProbability;

            emit log_named_uint("Element", i);
            emit log_named_uint("Weight", elements[i]);
            emit log_named_uint("Total Weight", totalWeight);
            emit log_named_uint("Expected P", expectedProbability);
            emit log_string("---");
        }
        
        // Generate 10,000 random variates
        for (uint256 i = 0; i < numRuns; i++) {
            uint256 elementIndex = 0; // LibDDRV.generate(forest, seeds[i]);
            countElementGenerated[elementIndex]++;
        }

        // Compare actual count of times generated vs. expected probabilities, with 10% tolerance
        for (uint256 i = 0; i < numElements; i++) {
            assertApproxEqRel(countElementGenerated[i], expectedProbabilities[i], 0.1e18);
        }
    }
}
