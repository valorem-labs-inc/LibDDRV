// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "src/LibDDRV.sol";

/// @notice Unit tests for LibDDRV
contract LibDDRVUnitTest is Test {
    Forest internal forest;
    uint256[] internal seeds;
    uint256 SEED_COUNT = 1000;

    /// @dev Convenience empty array for element Nodes without children
    Edge[] internal none;

    function setUp() public {
        seeds.push(uint256(keccak256(abi.encode(0))));
        for (uint256 i = 1; i < SEED_COUNT; i++) {
            seeds.push(uint256(keccak256(abi.encode(seeds[i - 1] + i))));
        }
    }

    /*//////////////////////////////////////////////////////////////
    //  Utilities
    //////////////////////////////////////////////////////////////*/

    /// @dev Logs forest information to the console
    function logForest(Forest storage f) internal view {
        console.log("forest weight: %s", f.weight);
        for (uint256 level = 0; level < 10; level++) {
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

    /// @dev Writes the range of values [start, end) to the weights array, starting at index
    function addRange(uint256 index, uint256 start, uint256 end, uint256[] memory weights)
        internal
        pure
        returns (uint256[] memory)
    {
        for (uint256 i = start; i < end; i++) {
            weights[index++] = i;
        }
        return weights;
    }

    /// @dev Assertion helper for Node struct. Note this only checks children.length, not the actual children.
    function assertEq(Node memory a, Node memory b, string memory message) internal {
        assertEq(a.index, b.index, message);
        assertEq(a.weight, b.weight, message);
        assertEq(a.children.length, b.children.length, message);
    }

    /// @dev Assertion helper for Edge struct. TODO TBD if needed.
    function assertEq(Edge memory a, Edge memory b, string memory message) internal {
        assertEq(a.level, b.level, message);
        assertEq(a.index, b.index, message);
    }

    /// @dev Finds the Node to which a given Edge connects.
    function nodeFor(Edge memory edge) internal view returns (Node memory) {
        return forest.levels[edge.level].ranges[edge.index];
    }

    /*//////////////////////////////////////////////////////////////
    //  Preprocess
    //////////////////////////////////////////////////////////////*/

    function testPreprocess_simple() public {
        uint256[] memory weights = new uint256[](2);
        weights[0] = 50;
        weights[1] = 50;

        LibDDRV.preprocess(forest, weights);

        // total weight should be the sum
        assertEq(forest.weight, 100);

        // The two weights should exist as leaves on level 0
        assertEq(forest.levels[0].ranges[0].weight, 50);
        assertEq(forest.levels[0].ranges[1].weight, 50);

        logForest(forest);

        // two elements should be in the only range on level 1
        assertEq(forest.levels[0].weight, 100);
    }

    /*
                          R2,5  Step 3: pop enqueued range R2,5 from queue and check if it has >1 child
                        /				it does not, so add R2,5 to the roots on level 2
                      / 				Done!
                    / 
                  /  
                /
            R1,3			Step 2: pop enqueued range R1,3 from queue, and check if it has >1 child
         / |  \  \					it does, so calculate L2 range that R1,3 falls into
        /  |   \    \					ilg2(4+5+6+7) = 5
      /   |     \    \				add, enqueue R2,5
    /    |     |     \
    4 	 5     6      7	    Step 1: 4,5,6,7 e [2^2, 2^3] => 2^j-1 = 2^2 => j = 3; 
                            Create range R1,3 and augment weight; 
                            enqueue R1,3
    */
    // Test that the forest is built correctly when there are more 4 elements
    function testPreprocess_oneTree() public {
        uint256[] memory weights = new uint256[](4);
        uint256 expectedWeight = 22; //E i [4,7]
        addRange(0, 4, 8, weights);

        LibDDRV.preprocess(forest, weights);

        logForest(forest);

        // total weight should be the sum
        assertEq(forest.weight, expectedWeight, "assert forest weight");
        assertEq(forest.levels[0].weight, expectedWeight, "assert l0 weight");
        // Should be zero, since we only add weight for root ranges
        assertEq(forest.levels[1].weight, 0, "assert l1 weight");
        assertEq(forest.levels[2].weight, expectedWeight, "assert l2 weight");

        uint256 l1RangeIndex = LibDDRV.floor_ilog(7) + 1;
        uint256 l2RangeIndex = LibDDRV.floor_ilog(expectedWeight) + 1;

        console.log("l1 index %s", l1RangeIndex);
        console.log("l2 index %s", l2RangeIndex);

        // range weighs 22, and is not a root range
        assertEq(forest.levels[1].ranges[l1RangeIndex].weight, 22, "assert l1 index range weight");
        assertEq(forest.levels[1].roots, 0, "assert no roots in l1");
        // assert children for l1 range
        assertEq(forest.levels[1].ranges[l1RangeIndex].children.length, 4, "assert l1 index range children length");

        // range weighs 22, and is the only root range
        assertEq(forest.levels[2].ranges[l2RangeIndex].weight, expectedWeight, "assert l2 index range weight");
        assertEq(forest.levels[2].roots, l2RangeIndex, "assert roots in l2");
        // assert children for l2 range
        assertEq(forest.levels[2].ranges[l2RangeIndex].children.length, 1, "assert l2 index range children length");
    }

    function testPreprocess_twoTrees() public {
        // A test which adds weights 4-7, and 64-127 to the forest
        uint256 expectedWeight = 6134; // E(64-127) == 6112, + 22 = 6134
        uint256[] memory weights = new uint256[](68);
        addRange(0, 4, 8, weights); // -> elts into R1,3; R1,3 into R2,5 (E(4-7) == 22, ilg2(22) = 5)
        addRange(4, 64, 128, weights); // -> elts into R1,7; R1,7 into R2,13 (ilg2(6112) = 13)

        LibDDRV.preprocess(forest, weights);
        assertEq(forest.weight, expectedWeight);
        assertEq(forest.levels[0].weight, expectedWeight);
        // Should be zero, since we only add weight for root ranges
        assertEq(forest.levels[1].weight, 0);
        assertEq(forest.levels[1].roots, 0);

        // roots field is the sum of the root range indices
        assertEq(forest.levels[2].roots, 5 + 13);
        assertEq(forest.levels[2].weight, expectedWeight);

        // R1,3 should have weight 22, and 4 children
        assertEq(forest.levels[1].ranges[3].weight, 22);
        assertEq(forest.levels[1].ranges[3].children.length, 4);

        // R1,7 should have weight 6112, and 64 children
        assertEq(forest.levels[1].ranges[7].weight, 6112);
        assertEq(forest.levels[1].ranges[7].children.length, 64);

        // R2,5 should have weight 22, and 1 child
        assertEq(forest.levels[2].ranges[5].weight, 22);
        assertEq(forest.levels[2].ranges[5].children.length, 1);

        // R2,13 should have weight 6112, and 1 child
        assertEq(forest.levels[2].ranges[13].weight, 6112);
        assertEq(forest.levels[2].ranges[13].children.length, 1);
    }

    /*//////////////////////////////////////////////////////////////
    //  Insert
    //////////////////////////////////////////////////////////////*/

    function test_insert() public {
        // LibDDRV.insert_element(0, 5, forest);

        assertEq(forest.weight, 5, "forest weight");
        assertEq(forest.levels[0].weight, 5, "level 0 weight");
        assertEq(forest.levels[1].weight, 5, "level 1 weight");
    }

    function testFuzz_insert(uint256 weight) public {
        // LibDDRV.insert_element(0, weight, forest);

        assertEq(forest.weight, weight, "forest weight");
        assertEq(forest.levels[0].weight, weight, "level 0 weight");
        assertEq(forest.levels[1].weight, weight, "level 1 weight");
    }

    /*//////////////////////////////////////////////////////////////
    //  Update
    //////////////////////////////////////////////////////////////*/

    function testUpdate_simple() public {
        uint256[] memory weights = new uint256[](2);
        weights[0] = 50;
        weights[1] = 50;

        LibDDRV.preprocess(forest, weights);
        // Log2(50) = 6, so the range is R1,6
        assertEq(forest.levels[1].ranges[6].weight, 100);
        // R1,6 should have two children
        assertEq(forest.levels[1].ranges[6].children.length, 2);
        // R2,7 should have weight 100, and 1 child
        assertEq(forest.levels[2].ranges[7].weight, 100);
        assertEq(forest.levels[2].ranges[7].children.length, 1);

        console.log("updating element");

        LibDDRV.update_element(forest, 0, 30);
        assertEq(forest.levels[0].weight, 80, "l0 weight is 80");
        assertEq(forest.levels[0].ranges[0].weight, 30, "first elt weight is 30");
        assertEq(forest.levels[0].ranges[1].weight, 50, "second elt weight is 50");
        assertEq(forest.weight, 80, "forest weight is 80");
        assertEq(forest.levels[1].ranges[6].weight, 80, "R1,6 is 80");
    }

    modifier withUpdateBackground() {
        // Given The Forest contains the following 11 Elements:
        //     | Element | Weight |
        //     | 1       | 10     |
        //     | 2       | 5      |
        //     | 3       | 15     |
        //     | 4       | 20     |
        //     | 5       | 5      |
        //     | 6       | 5      |
        //     | 7       | 5      |
        //     | 8       | 5      |
        //     | 9       | 10     |
        //     | 10      | 10     |
        //     | 11      | 10     |
        uint256[] memory weights = new uint256[](11);
        weights[0] = 10;
        weights[1] = 5;
        weights[2] = 15;
        weights[3] = 20;
        weights[4] = 5;
        weights[5] = 5;
        weights[6] = 5;
        weights[7] = 5;
        weights[8] = 10;
        weights[9] = 10;
        weights[10] = 10;
        LibDDRV.preprocess(weights, forest);

        // And The total weight of the Forest is 100
        assertEq(forest.weight, 100, "Forest total weight");

        // And There are 2 Levels in the Forest
        // assertEq(forest.levels.length, 2, "Levels count");

        // And The weight of Level 1 is 20
        assertEq(forest.levels[1].weight, 20, "Level 1 weight");

        // And The weight of Level 2 is 80
        assertEq(forest.levels[2].weight, 80, "Level 2 weight");

        // And The weight of Range R₃⁽¹⁾ should be 25
        assertEq(forest.levels[1].ranges[3].index, 3, unicode"Range R₃⁽¹⁾ index");
        assertEq(forest.levels[1].ranges[3].weight, 25, unicode"Range R₃⁽¹⁾ weight");

        // And The weight of Range R₄⁽¹⁾ should be 55
        assertEq(forest.levels[1].ranges[4].index, 4, unicode"Range R₄⁽¹⁾ index");
        assertEq(forest.levels[1].ranges[4].weight, 55, unicode"Range R₄⁽¹⁾ weight");

        // And The weight of Range R₅⁽¹⁾ should be 20
        assertEq(forest.levels[1].ranges[5].index, 5, unicode"Range R₅⁽¹⁾ index");
        assertEq(forest.levels[1].ranges[5].weight, 20, unicode"Range R₅⁽¹⁾ weight");

        // And The weight of Range R₅⁽²⁾ should be 25
        assertEq(forest.levels[2].ranges[5].index, 5, unicode"Range R₅⁽²⁾ index");
        assertEq(forest.levels[2].ranges[5].weight, 25, unicode"Range R₅⁽²⁾ weight");

        // And The weight of Range R₆⁽²⁾ should be 55
        assertEq(forest.levels[2].ranges[6].index, 6, unicode"Range R₆⁽²⁾ index");
        assertEq(forest.levels[2].ranges[6].weight, 55, unicode"Range R₆⁽²⁾ weight");

        // And The Forest has the following structure:
        //     | Element | E Weight | Parent | P Weight | Grandparent | GP Weight |
        //     | 2       | 5        | R₃⁽¹⁾  | (25)     | R₅⁽²⁾       | 25        |
        //     | 5       | 5        | R₃⁽¹⁾  | (25)     | R₅⁽²⁾       | 25        |
        //     | 6       | 5        | R₃⁽¹⁾  | (25)     | R₅⁽²⁾       | 25        |
        //     | 7       | 5        | R₃⁽¹⁾  | (25)     | R₅⁽²⁾       | 25        |
        //     | 8       | 5        | R₃⁽¹⁾  | (25)     | R₅⁽²⁾       | 25        |
        //     | 1       | 10       | R₄⁽¹⁾  | (55)     | R₆⁽²⁾       | 55        |
        //     | 3       | 15       | R₄⁽¹⁾  | (55)     | R₆⁽²⁾       | 55        |
        //     | 9       | 10       | R₄⁽¹⁾  | (55)     | R₆⁽²⁾       | 55        |
        //     | 10      | 10       | R₄⁽¹⁾  | (55)     | R₆⁽²⁾       | 55        |
        //     | 11      | 10       | R₄⁽¹⁾  | (55)     | R₆⁽²⁾       | 55        |
        //     | 4       | 20       | R₅⁽¹⁾  | 20       |             |           |

        // Check the children of parent Range R₃⁽¹⁾
        assertEq(forest.levels[1].ranges[3].children.length, 5, unicode"Range R₃⁽¹⁾ children count");
        assertEq(
            nodeFor(forest.levels[1].ranges[3].children[0]),
            Node({index: 1, weight: 5, children: none}),
            unicode"Range R₃⁽¹⁾ child 1"
        );
        assertEq(
            nodeFor(forest.levels[1].ranges[3].children[1]),
            Node({index: 4, weight: 5, children: none}),
            unicode"Range R₃⁽¹⁾ child 2"
        );
        assertEq(
            nodeFor(forest.levels[1].ranges[3].children[2]),
            Node({index: 5, weight: 5, children: none}),
            unicode"Range R₃⁽¹⁾ child 3"
        );
        assertEq(
            nodeFor(forest.levels[1].ranges[3].children[3]),
            Node({index: 6, weight: 5, children: none}),
            unicode"Range R₃⁽¹⁾ child 4"
        );
        assertEq(
            nodeFor(forest.levels[1].ranges[3].children[4]),
            Node({index: 7, weight: 5, children: none}),
            unicode"Range R₃⁽¹⁾ child 5"
        );

        // Check the children of parent Range R₄⁽¹⁾
        assertEq(forest.levels[1].ranges[4].children.length, 5, unicode"Range R₄⁽¹⁾ children count");
        assertEq(
            nodeFor(forest.levels[1].ranges[3].children[0]),
            Node({index: 0, weight: 10, children: none}),
            unicode"Range R₄⁽¹⁾ child 1"
        );
        assertEq(
            nodeFor(forest.levels[1].ranges[3].children[1]),
            Node({index: 2, weight: 15, children: none}),
            unicode"Range R₄⁽¹⁾ child 2"
        );
        assertEq(
            nodeFor(forest.levels[1].ranges[3].children[2]),
            Node({index: 8, weight: 10, children: none}),
            unicode"Range R₄⁽¹⁾ child 3"
        );
        assertEq(
            nodeFor(forest.levels[1].ranges[3].children[3]),
            Node({index: 9, weight: 10, children: none}),
            unicode"Range R₄⁽¹⁾ child 4"
        );
        assertEq(
            nodeFor(forest.levels[1].ranges[3].children[4]),
            Node({index: 10, weight: 10, children: none}),
            unicode"Range R₄⁽¹⁾ child 5"
        );

        // Check the children of parent Range R₅⁽¹⁾
        assertEq(forest.levels[1].ranges[5].children.length, 1, unicode"Range R₅⁽¹⁾ children count");
        assertEq(
            nodeFor(forest.levels[1].ranges[5].children[0]),
            Node({index: 3, weight: 20, children: none}),
            unicode"Range R₅⁽¹⁾ child 1"
        );

        // Check the children of grandparent Range R₅⁽²⁾
        assertEq(forest.levels[2].ranges[5].children.length, 1, unicode"Range R₅⁽²⁾ children count");
        assertEq(
            nodeFor(forest.levels[2].ranges[5].children[0]),
            Node({index: 3, weight: 25, children: new Edge[](5)}),
            unicode"Range R₅⁽²⁾ child 1"
        );

        // Check the children of grandparent Range R₆⁽²⁾
        assertEq(forest.levels[2].ranges[6].children.length, 1, unicode"Range R₆⁽²⁾ children count");
        assertEq(
            nodeFor(forest.levels[2].ranges[6].children[0]),
            Node({index: 4, weight: 55, children: new Edge[](5)}),
            unicode"Range R₆⁽²⁾ child 1"
        );

        _;
    }

    // Scenario: C -- Update 1 Element, decrease weight, moves to lower range numbered-parent
    function test_update_scenarioC() public withUpdateBackground {
        // When I update Element 3 from weight 15 to weight 6
        LibDDRV.update_element(2, 6, forest);

        // Then The parent of Element 3 should now be Range R₃⁽¹⁾
        // TODO

        // And The total weight of the Forest should be 91
        assertEq(forest.weight, 91, "Forest total weight");

        // And There should still be 2 Levels in the Forest
        //

        // And The weight of Level 1 should still be 20
        assertEq(forest.levels[0].weight, 20, "Level 1 weight");

        // And The weight of Level 2 should be 71
        assertEq(forest.levels[1].weight, 71, "Level 2 weight");

        // And The weight of Range R₃⁽¹⁾ should be 31
        assertEq(forest.levels[1].ranges[3].index, 3, unicode"Range R₃⁽¹⁾ index");
        assertEq(forest.levels[1].ranges[3].weight, 31, unicode"Range R₃⁽¹⁾ weight");

        // And The weight of Range R₄⁽¹⁾ should be 40
        assertEq(forest.levels[1].ranges[4].index, 4, unicode"Range R₄⁽¹⁾ index");
        assertEq(forest.levels[1].ranges[4].weight, 40, unicode"Range R₄⁽¹⁾ weight");

        // And The weight of Range R₅⁽¹⁾ should still be 20
        assertEq(forest.levels[1].ranges[5].index, 5, unicode"Range R₅⁽¹⁾ index");
        assertEq(forest.levels[1].ranges[5].weight, 20, unicode"Range R₅⁽¹⁾ weight");

        // And The weight of Range R₅⁽²⁾ should be 31
        assertEq(forest.levels[2].ranges[5].index, 5, unicode"Range R₅⁽²⁾ index");
        assertEq(forest.levels[2].ranges[5].weight, 31, unicode"Range R₅⁽²⁾ weight");

        // And The weight of Range R₆⁽²⁾ should be 40
        assertEq(forest.levels[2].ranges[6].index, 6, unicode"Range R₆⁽²⁾ index");
        assertEq(forest.levels[2].ranges[6].weight, 40, unicode"Range R₆⁽²⁾ weight");

        // And The Forest should have the following structure:
        //     | Element | E Weight | Parent | P Weight | Grandparent | GP Weight |
        //     | 2       | 5        | R₃⁽¹⁾  | (31)     | R₅⁽²⁾       | 31        |
        //     | 3       | 6 *      | R₃⁽¹⁾  | (31)     | R₅⁽²⁾       | 31        |
        //     | 5       | 5        | R₃⁽¹⁾  | (31)     | R₅⁽²⁾       | 31        |
        //     | 6       | 5        | R₃⁽¹⁾  | (31)     | R₅⁽²⁾       | 31        |
        //     | 7       | 5        | R₃⁽¹⁾  | (31)     | R₅⁽²⁾       | 31        |
        //     | 8       | 5        | R₃⁽¹⁾  | (31)     | R₅⁽²⁾       | 31        |
        //     | 1       | 10       | R₄⁽¹⁾  | (40)     | R₆⁽²⁾       | 40        |
        //     | 9       | 10       | R₄⁽¹⁾  | (40)     | R₆⁽²⁾       | 40        |
        //     | 10      | 10       | R₄⁽¹⁾  | (40)     | R₆⁽²⁾       | 40        |
        //     | 11      | 10       | R₄⁽¹⁾  | (40)     | R₆⁽²⁾       | 40        |
        //     | 4       | 20       | R₅⁽¹⁾  | 20       |             |           |

        // Check the children of parent Range R₃⁽¹⁾
        assertEq(forest.levels[1].ranges[3].children.length, 6, unicode"Range R₃⁽¹⁾ children count");
        assertEq(
            nodeFor(forest.levels[1].ranges[3].children[0]),
            Node({index: 1, weight: 5, children: none}),
            unicode"Range R₃⁽¹⁾ child 1"
        );
        assertEq(
            nodeFor(forest.levels[1].ranges[3].children[1]),
            Node({index: 4, weight: 5, children: none}),
            unicode"Range R₃⁽¹⁾ child 2"
        );
        assertEq(
            nodeFor(forest.levels[1].ranges[3].children[2]),
            Node({index: 5, weight: 5, children: none}),
            unicode"Range R₃⁽¹⁾ child 3"
        );
        assertEq(
            nodeFor(forest.levels[1].ranges[3].children[3]),
            Node({index: 6, weight: 5, children: none}),
            unicode"Range R₃⁽¹⁾ child 4"
        );
        assertEq(
            nodeFor(forest.levels[1].ranges[3].children[4]),
            Node({index: 7, weight: 5, children: none}),
            unicode"Range R₃⁽¹⁾ child 5"
        );
        assertEq(
            nodeFor(forest.levels[1].ranges[3].children[5]),
            Node({index: 2, weight: 6, children: none}),
            unicode"Range R₃⁽¹⁾ child 6"
        );

        // Check the children of parent Range R₄⁽¹⁾
        assertEq(forest.levels[1].ranges[4].children.length, 4, unicode"Range R₄⁽¹⁾ children count");
        assertEq(
            nodeFor(forest.levels[1].ranges[3].children[0]),
            Node({index: 0, weight: 10, children: none}),
            unicode"Range R₄⁽¹⁾ child 1"
        );
        assertEq(
            nodeFor(forest.levels[1].ranges[3].children[1]),
            Node({index: 8, weight: 10, children: none}),
            unicode"Range R₄⁽¹⁾ child 2"
        );
        assertEq(
            nodeFor(forest.levels[1].ranges[3].children[2]),
            Node({index: 9, weight: 10, children: none}),
            unicode"Range R₄⁽¹⁾ child 3"
        );
        assertEq(
            nodeFor(forest.levels[1].ranges[3].children[3]),
            Node({index: 10, weight: 10, children: none}),
            unicode"Range R₄⁽¹⁾ child 4"
        );

        // Check the children of parent Range R₅⁽¹⁾
        assertEq(forest.levels[1].ranges[5].children.length, 1, unicode"Range R₅⁽¹⁾ children count");
        assertEq(
            nodeFor(forest.levels[1].ranges[5].children[0]),
            Node({index: 3, weight: 20, children: none}),
            unicode"Range R₅⁽¹⁾ child 1"
        );

        // Check the children of grandparent Range R₅⁽²⁾
        assertEq(forest.levels[2].ranges[5].children.length, 1, unicode"Range R₅⁽²⁾ children count");
        assertEq(
            nodeFor(forest.levels[2].ranges[5].children[0]),
            Node({index: 3, weight: 25, children: new Edge[](6)}),
            unicode"Range R₅⁽²⁾ child 1"
        );

        // Check the children of grandparent Range R₆⁽²⁾
        assertEq(forest.levels[2].ranges[6].children.length, 1, unicode"Range R₆⁽²⁾ children count");
        assertEq(
            nodeFor(forest.levels[2].ranges[6].children[0]),
            Node({index: 4, weight: 55, children: new Edge[](4)}),
            unicode"Range R₆⁽²⁾ child 1"
        );
    }

    // TODO convert remaining 17 Cucumber scenarios to Forge tests

    /*//////////////////////////////////////////////////////////////
    //  Generate
    //////////////////////////////////////////////////////////////*/

    function testGenerate_simple() public {
        uint256[] memory weights = new uint256[](2);
        weights[0] = 50;
        weights[1] = 50;

        LibDDRV.preprocess(forest, weights);
        uint256 element = LibDDRV.generate(forest, 0);
        assertTrue(element == 0 || element == 1);
    }

    function testGenerate() public {
        uint256 countHeads = 0;
        uint256 countTails = 0;
        uint256[] memory weights = new uint256[](2);
        weights[0] = 50;
        weights[1] = 50;

        LibDDRV.preprocess(forest, weights);

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
