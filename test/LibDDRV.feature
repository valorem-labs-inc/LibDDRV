Feature: Dynamic Discrete Random Variates

    As a Solidity Developer,
    I want to generate random variates from a discrete distribution of dynamically weighted elements in sublinear time,
    so that I can make probabilistic selections in my smart contracts.

    # Preprocess

    Scenario: Preprocess 0 Elements
        Given An empty and uninstantiated Forest
        When I preprocess the Forest
        Then The Forest should be instantiated and empty

    Scenario: Preprocess 1 Element
        Given An empty and uninstantiated Forest
        When I preprocess the Forest with the following 1 Element:
            | Element | Weight |
            | 1       | 10     |
        Then The Forest should have the following structure:
            | Element | E Weight | Parent | P Weight |
            | 1       | 10       | R₄⁽¹⁾  | 10       |

    Scenario: Preprocess 10 Elements
        Given An empty and uninstantiated Forest
        When I preprocess the Forest with the following 10 Elements:
            | Element | Weight |
            | 1       | 5      |
            | 2       | 4      |
            | 3       | 5      |
            | 4       | 7      |
            | 5       | 6      |
            | 6       | 4      |
            | 7       | 4      |
            | 8       | 5      |
            | 9       | 6      |
            | 10      | 7      |
        Then The Forest should have the following structure: TODO
            | Element | E Weight | Parent | P Weight |
            | 1       | 5        | R₄⁽¹⁾  | 53       |
            | 2       | 4        | R₄⁽¹⁾  | 53       |
            | 3       | 5        | R₄⁽¹⁾  | 53       |
            | 4       | 7        | R₄⁽¹⁾  | 53       |
            | 5       | 6        | R₄⁽¹⁾  | 53       |
            | 6       | 4        | R₄⁽¹⁾  | 53       |
            | 7       | 4        | R₄⁽¹⁾  | 53       |
            | 8       | 5        | R₄⁽¹⁾  | 53       |
            | 9       | 6        | R₄⁽¹⁾  | 53       |
            | 10      | 7        | R₄⁽¹⁾  | 53       |

    # Insert

    Scenario: Insert 1 Element
        Given A Forest with the following 1 Element:
            | Element | Weight |
            | 1       | 7      |
        When I insert the following 1 Element:
            | Element | Weight |
            | 2       | 5      |
        Then The Forest should have the following structure: TODO
            | Element | E Weight | Parent | P Weight |
            | 1       | 10       | R₄⁽¹⁾  | 12       |
            | 2       | 5        | R₄⁽¹⁾  | 12       |

    Scenario: Insert 1 Element 10 times

    Scenario: Insert 1 Element 100 times

    # Update

    #*//////////////////////////////////////////////////////////////////////////
    #
    #   Visual Representation of Forest with 11 Elements
    #
    #                  R₆⁽²⁾                R₅⁽²⁾          <--- Level 2
    #                   |                    |
    #                   |                    |
    #                   |                    |
    #    R₅⁽¹⁾         R₄⁽¹⁾                R₃⁽¹⁾          <--- Level 1
    #     |         / / |  \ \           / / |  \ \
    #     |       /  |  |  |  \        /  |  |  |  \
    #     |      /   |  |  |   \      /   |  |  |   \
    #     4     11  10  9  3   1     8   7   6  5   2      <--- Elements
    #
    #/////////////////////////////////////////////////////////////////////////*/

    Background: Forest with 11 Elements, 3 Root Ranges, 2 Levels, and total weight of 100
        # NOTE this background applies only to Update scenarios
        Given The Forest contains the following 11 Elements:
            | Element | Weight |
            | 1       | 10     |
            | 2       | 5      |
            | 3       | 15     |
            | 4       | 20     |
            | 5       | 5      |
            | 6       | 5      |
            | 7       | 5      |
            | 8       | 5      |
            | 9       | 10     |
            | 10      | 10     |
            | 11      | 10     |
        And The total weight of the Forest is 100
        And There are 2 Levels in the Forest
        And The weight of Level 1 is 20
        And The weight of Level 2 is 80
        And The Forest has the following structure:
            | Element | E Weight | Parent | P Weight | Grandparent | GP Weight |
            | 2       | 5        | R₃⁽¹⁾  | (25)     | R₅⁽²⁾       | 25        |
            | 5       | 5        | R₃⁽¹⁾  | (25)     | R₅⁽²⁾       | 25        |
            | 6       | 5        | R₃⁽¹⁾  | (25)     | R₅⁽²⁾       | 25        |
            | 7       | 5        | R₃⁽¹⁾  | (25)     | R₅⁽²⁾       | 25        |
            | 8       | 5        | R₃⁽¹⁾  | (25)     | R₅⁽²⁾       | 25        |
            | 1       | 10       | R₄⁽¹⁾  | (55)     | R₆⁽²⁾       | 55        |
            | 3       | 15       | R₄⁽¹⁾  | (55)     | R₆⁽²⁾       | 55        |
            | 9       | 10       | R₄⁽¹⁾  | (55)     | R₆⁽²⁾       | 55        |
            | 10      | 10       | R₄⁽¹⁾  | (55)     | R₆⁽²⁾       | 55        |
            | 11      | 10       | R₄⁽¹⁾  | (55)     | R₆⁽²⁾       | 55        |
            | 4       | 20       | R₅⁽¹⁾  | 20       |             |           |

    @Revert
    Scenario: A -- Update 1 Element, no change in weight, no change in parent
        When I update Element 8 from weight 5 to weight 5
        Then The transaction should revert with a NewWeightMustBeDifferent error

    Scenario: B -- Update 1 Element, decrease weight, no change in parent
        When I update Element 8 from weight 5 to weight 4
        Then The parent of Element 8 should still be Range R₃⁽¹⁾
        And The total weight of the Forest should be 99
        And There should still be 2 Levels in the Forest
        And The weight of Level 1 should still be 20
        And The weight of Level 2 should be 79
        And The weight of Range R₃⁽¹⁾ should be 24
        And The weight of Range R₅⁽²⁾ should be 24
        And The weight of Range R₄⁽¹⁾ should still be 55
        And The weight of Range R₆⁽²⁾ should still be 55
        And The weight of Range R₅⁽¹⁾ should still be 20
        And The Forest should not change its structure

    Scenario: C -- Update 1 Element, decrease weight, moves to lower range numbered-parent
        When I update Element 3 from weight 15 to weight 6

        Then The parent of Element 3 should now be Range R₃⁽¹⁾

        And The total weight of the Forest should be 91
        And There should still be 2 Levels in the Forest
        And The weight of Level 1 should still be 20
        And The weight of Level 2 should be 71
        And The weight of Range R₃⁽¹⁾ should be 31
        And The weight of Range R₄⁽¹⁾ should be 40
        And The weight of Range R₅⁽¹⁾ should still be 20
        And The weight of Range R₅⁽²⁾ should be 31
        And The weight of Range R₆⁽²⁾ should be 40

        And The Forest should have the following structure:
            | Element | E Weight | Parent | P Weight | Grandparent | GP Weight |
            | 2       | 5        | R₃⁽¹⁾  | (31)     | R₅⁽²⁾       | 31        |
            | 3       | 6 *      | R₃⁽¹⁾  | (31)     | R₅⁽²⁾       | 31        |
            | 5       | 5        | R₃⁽¹⁾  | (31)     | R₅⁽²⁾       | 31        |
            | 6       | 5        | R₃⁽¹⁾  | (31)     | R₅⁽²⁾       | 31        |
            | 7       | 5        | R₃⁽¹⁾  | (31)     | R₅⁽²⁾       | 31        |
            | 8       | 5        | R₃⁽¹⁾  | (31)     | R₅⁽²⁾       | 31        |
            | 1       | 10       | R₄⁽¹⁾  | (40)     | R₆⁽²⁾       | 40        |
            | 9       | 10       | R₄⁽¹⁾  | (40)     | R₆⁽²⁾       | 40        |
            | 10      | 10       | R₄⁽¹⁾  | (40)     | R₆⁽²⁾       | 40        |
            | 11      | 10       | R₄⁽¹⁾  | (40)     | R₆⁽²⁾       | 40        |
            | 4       | 20       | R₅⁽¹⁾  | 20       |             |           |

    Scenario: D -- Update 1 Element, increase weight, no change in parent
        When I update Element 8 from weight 5 to weight 7
        Then The parent of Element 8 should still be Range R₃⁽¹⁾
        And The total weight of the forest should be 102
        And There should be 2 Levels in the Forest
        And The weight of Level 1 should be 20
        And The weight of Level 2 should be 82
        And The weight of Range R₅⁽²⁾ should be 27
        And The weight of Range R₆⁽²⁾ should be 55
        And The Forest should not change its structure

    Scenario: E -- Update 1 Element, increase weight, moves to higher range numbered-parent
        When I update Element 8 from weight 5 to weight 8
        Then The parent of Element 8 should now be Range R₄⁽¹⁾
        And The total weight of the forest should be 103
        And There should be 2 Levels in the Forest
        And The weight of Level 1 should be 20
        And The weight of Level 2 should be 83
        And The weight of Range R₅⁽²⁾ should be 20
        And The weight of Range R₆⁽²⁾ should be 63
        And The Forest should have the following structure:
            | Element | E Weight | Parent | P Weight | Grandparent | GP Weight |
            | 2       | 5        | R₃⁽¹⁾  | (20)     | R₅⁽²⁾       | 20        |
            | 5       | 5        | R₃⁽¹⁾  | (20)     | R₅⁽²⁾       | 20        |
            | 6       | 5        | R₃⁽¹⁾  | (20)     | R₅⁽²⁾       | 20        |
            | 7       | 5        | R₃⁽¹⁾  | (20)     | R₅⁽²⁾       | 20        |
            | 1       | 10       | R₄⁽¹⁾  | (63)     | R₆⁽²⁾       | 63        |
            | 3       | 15       | R₄⁽¹⁾  | (63)     | R₆⁽²⁾       | 63        |
            | 8       | 8 *      | R₄⁽¹⁾  | (63)     | R₆⁽²⁾       | 63        |
            | 9       | 10       | R₄⁽¹⁾  | (63)     | R₆⁽²⁾       | 63        |
            | 10      | 10       | R₄⁽¹⁾  | (63)     | R₆⁽²⁾       | 63        |
            | 11      | 10       | R₄⁽¹⁾  | (63)     | R₆⁽²⁾       | 63        |
            | 4       | 20       | R₅⁽¹⁾  | 20       |             |           |

    Scenario: F -- Update 1 Element, decrease weight, moves to lower range numbered-parent, 1 grandparent dies, 1 Level is added
        When I update Element 3 from weight 15 to weight 7
        Then The parent of Element 3 should now be Range R₃⁽¹⁾
        And The parent of Range R₃⁽¹⁾ should now be Range R₆⁽²⁾
        And The total weight of the forest should be 92
        And There should be 3 Levels in the Forest
        And The weight of Level 1 should be 20
        And The weight of Level 2 should be 0
        And The weight of Level 3 should be 72
        And The weight of Range R₆⁽³⁾ should be 72
        And The Forest should have the following structure:
            | Element | E Weight | Parent | P Weight | Grandparent | GP Weight | Greatgrandparent | GGP Weight |
            | 2       | 5        | R₃⁽¹⁾  | (32)     | R₆⁽²⁾       | (72)      | R₇⁽³⁾            | 72         |
            | 3       | 7 *      | R₃⁽¹⁾  | (32)     | R₆⁽²⁾       | (72)      | R₇⁽³⁾            | 72         |
            | 5       | 5        | R₃⁽¹⁾  | (32)     | R₆⁽²⁾       | (72)      | R₇⁽³⁾            | 72         |
            | 6       | 5        | R₃⁽¹⁾  | (32)     | R₆⁽²⁾       | (72)      | R₇⁽³⁾            | 72         |
            | 7       | 5        | R₃⁽¹⁾  | (32)     | R₆⁽²⁾       | (72)      | R₇⁽³⁾            | 72         |
            | 8       | 5        | R₃⁽¹⁾  | (32)     | R₆⁽²⁾       | (72)      | R₇⁽³⁾            | 72         |
            | 1       | 10       | R₄⁽¹⁾  | (40)     | R₆⁽²⁾       | (72)      | R₇⁽³⁾            | 72         |
            | 9       | 10       | R₄⁽¹⁾  | (40)     | R₆⁽²⁾       | (72)      | R₇⁽³⁾            | 72         |
            | 10      | 10       | R₄⁽¹⁾  | (40)     | R₆⁽²⁾       | (72)      | R₇⁽³⁾            | 72         |
            | 11      | 10       | R₄⁽¹⁾  | (40)     | R₆⁽²⁾       | (72)      | R₇⁽³⁾            | 72         |
            | 4       | 20       | R₅⁽¹⁾  | 20       |             |           |                  |            |

    Scenario: G -- Update 1 Element, increase weight, moves to higher range numbered-parent and -grandparent
        When I update Element 8 from weight 5 to weight 9
        Then The parent of Element 3 should now be Range R₄⁽¹⁾
        And The parent of Range R₄⁽¹⁾ should now be Range R₇⁽²⁾
        And The total weight of the forest should be 104
        And There should be 2 Levels in the Forest
        And The weight of Level 1 should be 20
        And The weight of Level 2 should be 84
        And The weight of Range R₅⁽²⁾ should be 20
        And The weight of Range R₆⁽²⁾ should be 0
        And The weight of Range R₇⁽²⁾ should be 64
        And The Forest should have the following structure:
            | Element | E Weight | Parent | P Weight | Grandparent | GP Weight |
            | 2       | 5        | R₃⁽¹⁾  | (20)     | R₅⁽²⁾       | 20        |
            | 5       | 5        | R₃⁽¹⁾  | (20)     | R₅⁽²⁾       | 20        |
            | 6       | 5        | R₃⁽¹⁾  | (20)     | R₅⁽²⁾       | 20        |
            | 7       | 5        | R₃⁽¹⁾  | (20)     | R₅⁽²⁾       | 20        |
            | 1       | 10       | R₄⁽¹⁾  | (64)     | R₇⁽²⁾       | 64        |
            | 3       | 15       | R₄⁽¹⁾  | (64)     | R₇⁽²⁾       | 64        |
            | 8       | 9 *      | R₄⁽¹⁾  | (64)     | R₇⁽²⁾       | 64        |
            | 9       | 10       | R₄⁽¹⁾  | (64)     | R₇⁽²⁾       | 64        |
            | 10      | 10       | R₄⁽¹⁾  | (64)     | R₇⁽²⁾       | 64        |
            | 11      | 10       | R₄⁽¹⁾  | (64)     | R₇⁽²⁾       | 64        |
            | 4       | 20       | R₅⁽¹⁾  | 20       |             |           |

    Scenario: H -- Update 5 Elements, decrease weight, moves to lower range numbered-parent and -grandparent
        When I update Element 8 from weight 5 to weight 3
        And I update Element 7 from weight 5 to weight 3
        And I update Element 6 from weight 5 to weight 3
        And I update Element 5 from weight 5 to weight 3
        And I update Element 2 from weight 5 to weight 3
        Then The parent of Element 8 should now be Range R₂⁽¹⁾
        And The parent of Element 7 should now be Range R₂⁽¹⁾
        And The parent of Element 6 should now be Range R₂⁽¹⁾
        And The parent of Element 5 should now be Range R₂⁽¹⁾
        And The parent of Element 2 should now be Range R₂⁽¹⁾
        And The parent of Range R₂⁽¹⁾ should now be Range R₄⁽²⁾
        And The total weight of the forest should be 90
        And There should be 2 Levels in the Forest
        And The weight of Level 1 should be 20
        And The weight of Level 2 should be 70
        And The weight of Range R₅⁽²⁾ should be 0
        And The weight of Range R₄⁽²⁾ should be 15
        And The Forest should have the following structure:
            | Element | E Weight | Parent | P Weight | Grandparent | GP Weight |
            | 2       | 3 *      | R₂⁽¹⁾  | (15)     | R₄⁽²⁾       | 15        |
            | 5       | 3 *      | R₂⁽¹⁾  | (15)     | R₄⁽²⁾       | 15        |
            | 6       | 3 *      | R₂⁽¹⁾  | (15)     | R₄⁽²⁾       | 15        |
            | 7       | 3 *      | R₂⁽¹⁾  | (15)     | R₄⁽²⁾       | 15        |
            | 8       | 3 *      | R₂⁽¹⁾  | (15)     | R₄⁽²⁾       | 15        |
            | 1       | 10       | R₄⁽¹⁾  | (55)     | R₆⁽²⁾       | 55        |
            | 3       | 15       | R₄⁽¹⁾  | (55)     | R₆⁽²⁾       | 55        |
            | 9       | 10       | R₄⁽¹⁾  | (55)     | R₆⁽²⁾       | 55        |
            | 10      | 10       | R₄⁽¹⁾  | (55)     | R₆⁽²⁾       | 55        |
            | 11      | 10       | R₄⁽¹⁾  | (55)     | R₆⁽²⁾       | 55        |
            | 4       | 20       | R₅⁽¹⁾  | 20       |             |           |

    Scenario: I -- Update 2 Elements, increase weight, moves to higher range numbered-grandparent, no change in parent
        When I update Element 9 from weight 10 to weight 15
        And I update Element 11 from weight 10 to weight 15
        Then The parent of Element 9 should still be Range R₄⁽¹⁾
        And The parent of Element 11 should still be Range R₄⁽¹⁾
        And The parent of Range R₄⁽¹⁾ should now be Range R₇⁽²⁾
        And The total weight of the forest should be 110
        And There should be 2 Levels in the Forest
        And The weight of Level 1 should be 20
        And The weight of Level 2 should be 90
        And The weight of Range R₆⁽²⁾ should be 0
        And The weight of Range R₇⁽²⁾ should be 65
        And The Forest has the following structure:
            | Element | E Weight | Parent | P Weight | Grandparent | GP Weight |
            | 2       | 5        | R₃⁽¹⁾  | (25)     | R₅⁽²⁾       | 25        |
            | 5       | 5        | R₃⁽¹⁾  | (25)     | R₅⁽²⁾       | 25        |
            | 6       | 5        | R₃⁽¹⁾  | (25)     | R₅⁽²⁾       | 25        |
            | 7       | 5        | R₃⁽¹⁾  | (25)     | R₅⁽²⁾       | 25        |
            | 8       | 5        | R₃⁽¹⁾  | (25)     | R₅⁽²⁾       | 25        |
            | 1       | 10       | R₄⁽¹⁾  | (65)     | R₇⁽²⁾       | 65        |
            | 3       | 15       | R₄⁽¹⁾  | (65)     | R₇⁽²⁾       | 65        |
            | 9       | 15 *     | R₄⁽¹⁾  | (65)     | R₇⁽²⁾       | 65        |
            | 10      | 10       | R₄⁽¹⁾  | (65)     | R₇⁽²⁾       | 65        |
            | 11      | 15 *     | R₄⁽¹⁾  | (65)     | R₇⁽²⁾       | 65        |
            | 4       | 20       | R₅⁽¹⁾  | 20       |             |           |

    Scenario: J -- Update 1 Element, increase weight, moves to much higher range numbered-parent
        When I update Element 4 from weight 20 to weight 127
        Then The parent of Element 4 should now be Range R₇⁽¹⁾
        And The total weight of the forest should be 207
        And There should be 2 Levels in the Forest
        And The weight of Level 1 should be 127
        And The weight of Level 2 should be 80
        And The weight of Range R₇⁽¹⁾ should be 127
        And The weight of Range R₅⁽¹⁾ should be 0
        And The Forest should have the following structure:
            | Element | E Weight | Parent | P Weight | Grandparent | GP Weight |
            | 2       | 5        | R₃⁽¹⁾  | (25)     | R₅⁽²⁾       | 25        |
            | 5       | 5        | R₃⁽¹⁾  | (25)     | R₅⁽²⁾       | 25        |
            | 6       | 5        | R₃⁽¹⁾  | (25)     | R₅⁽²⁾       | 25        |
            | 7       | 5        | R₃⁽¹⁾  | (25)     | R₅⁽²⁾       | 25        |
            | 8       | 5        | R₃⁽¹⁾  | (25)     | R₅⁽²⁾       | 25        |
            | 1       | 10       | R₄⁽¹⁾  | (55)     | R₆⁽²⁾       | 55        |
            | 3       | 15       | R₄⁽¹⁾  | (55)     | R₆⁽²⁾       | 55        |
            | 9       | 10       | R₄⁽¹⁾  | (55)     | R₆⁽²⁾       | 55        |
            | 10      | 10       | R₄⁽¹⁾  | (55)     | R₆⁽²⁾       | 55        |
            | 11      | 10       | R₄⁽¹⁾  | (55)     | R₆⁽²⁾       | 55        |
            | 4       | 127 *    | R₇⁽¹⁾  | 127      |             |           |

    Scenario: K -- Update 1 Element, increase weight, moves to much, much higher range numbered-parent
        When I update Element 4 from weight 20 to weight 128
        Then The parent of Element 4 should now be Range R₈⁽¹⁾
        And The total weight of the forest should be 208
        And There should be 2 Levels in the Forest
        And The weight of Level 1 should be 128
        And The weight of Level 2 should be 80
        And The weight of Range R₈⁽¹⁾ should be 128
        And The weight of Range R₅⁽¹⁾ should be 0
        And The Forest should have the following structure:
            | Element | E Weight | Parent | P Weight | Grandparent | GP Weight |
            | 2       | 5        | R₃⁽¹⁾  | (25)     | R₅⁽²⁾       | 25        |
            | 5       | 5        | R₃⁽¹⁾  | (25)     | R₅⁽²⁾       | 25        |
            | 6       | 5        | R₃⁽¹⁾  | (25)     | R₅⁽²⁾       | 25        |
            | 7       | 5        | R₃⁽¹⁾  | (25)     | R₅⁽²⁾       | 25        |
            | 8       | 5        | R₃⁽¹⁾  | (25)     | R₅⁽²⁾       | 25        |
            | 1       | 10       | R₄⁽¹⁾  | (55)     | R₆⁽²⁾       | 55        |
            | 3       | 15       | R₄⁽¹⁾  | (55)     | R₆⁽²⁾       | 55        |
            | 9       | 10       | R₄⁽¹⁾  | (55)     | R₆⁽²⁾       | 55        |
            | 10      | 10       | R₄⁽¹⁾  | (55)     | R₆⁽²⁾       | 55        |
            | 11      | 10       | R₄⁽¹⁾  | (55)     | R₆⁽²⁾       | 55        |
            | 4       | 128 *    | R₈⁽¹⁾  | 128      |             |           |

    Scenario: L -- Update 4 Elements, increase weight, 1 grandparent dies, no change in parent
        When I update Element 2 from weight 5 to weight 8
        And I update Element 6 from weight 5 to weight 6
        And I update Element 7 from weight 5 to weight 7
        And I update Element 8 from weight 5 to weight 6
        Then The parent of Element 2 should still be Range R₃⁽¹⁾
        And The parent of Element 6 should still be Range R₃⁽¹⁾
        And The parent of Element 7 should still be Range R₃⁽¹⁾
        And The parent of Element 8 should still be Range R₃⁽¹⁾
        And The parent of Range R₃⁽¹⁾ should now be Range R₆⁽²⁾
        And The total weight of the forest should be 107
        And There should be 2 Levels in the Forest
        And The weight of Level 1 should be 20
        And The weight of Level 2 should be 87
        And The weight of Range R₅⁽²⁾ should be 0
        And The weight of Range R₆⁽²⁾ should be 87
        And The Forest should have the following structure:
            | Element | E Weight | Parent | P Weight | Grandparent | GP Weight |
            | 2       | 8 *      | R₃⁽¹⁾  | (32)     | R₆⁽²⁾       | 87        |
            | 5       | 5        | R₃⁽¹⁾  | (32)     | R₆⁽²⁾       | 87        |
            | 6       | 6 *      | R₃⁽¹⁾  | (32)     | R₆⁽²⁾       | 87        |
            | 7       | 7 *      | R₃⁽¹⁾  | (32)     | R₆⁽²⁾       | 87        |
            | 8       | 6 *      | R₃⁽¹⁾  | (32)     | R₆⁽²⁾       | 87        |
            | 1       | 10       | R₄⁽¹⁾  | (55)     | R₆⁽²⁾       | 87        |
            | 3       | 15       | R₄⁽¹⁾  | (55)     | R₆⁽²⁾       | 87        |
            | 9       | 10       | R₄⁽¹⁾  | (55)     | R₆⁽²⁾       | 87        |
            | 10      | 10       | R₄⁽¹⁾  | (55)     | R₆⁽²⁾       | 87        |
            | 11      | 10       | R₄⁽¹⁾  | (55)     | R₆⁽²⁾       | 87        |
            | 4       | 20       | R₅⁽¹⁾  | 20       |             |           |

    Scenario: TODO Big jump

    Scenario: TODO 4 Levels
    Add Element 12 with weight 30
    Parent should R₅⁽¹⁾ with weight 50
    Grandparent should be R₆⁽²⁾ with weight XYZ
    Great Grandparent should be R₇⁽³⁾ with weight XYZ

    # Delete (implicit)

    Scenario: Delete 1 Element, 1 parent dies, 1 grandparent dies
        When I delete Element 2
        Then The parent of Element 2 should be null
        And The parent of Range R₃⁽¹⁾ should now be Range R₆⁽²⁾
        And The total weight of the forest should be 102
        And There should be 2 Levels in the Forest
        And The weight of Level 1 should be 20
        And The weight of Level 2 should be 82
        And The weight of Range R₅⁽²⁾ should be 0
        And The weight of Range R₆⁽²⁾ should be 82
        And The Forest should have the following structure:
            | Element | E Weight | Parent | P Weight | Grandparent | GP Weight |
            | 5       | 5        | R₃⁽¹⁾  | (27)     | R₆⁽²⁾       | 82        |
            | 6       | 6        | R₃⁽¹⁾  | (27)     | R₆⁽²⁾       | 82        |
            | 7       | 7        | R₃⁽¹⁾  | (27)     | R₆⁽²⁾       | 82        |
            | 8       | 6        | R₃⁽¹⁾  | (27)     | R₆⁽²⁾       | 82        |
            | 1       | 10       | R₄⁽¹⁾  | (55)     | R₆⁽²⁾       | 82        |
            | 3       | 15       | R₄⁽¹⁾  | (55)     | R₆⁽²⁾       | 82        |
            | 9       | 10       | R₄⁽¹⁾  | (55)     | R₆⁽²⁾       | 82        |
            | 10      | 10       | R₄⁽¹⁾  | (55)     | R₆⁽²⁾       | 82        |
            | 11d     | 10       | R₄⁽¹⁾  | (55)     | R₆⁽²⁾       | 82        |

    Scenario: Delete n Elements, decrease parent

    Scenario: Delete n Elements, increase parent

    # Generate

    Scenario: Generate dynamic random variate from set of 100 Elements
        Given The Forest contains the following 5 Elements:
            | Element | Weight |
            | 1       | 38     |
            | 2       | 4      |
            | 3       | 5      |
            | 4       | 12     |
            | 5       | 41     |
        When I generate 10,000 random variates
        Then The instances of each Element being selected should be approximately the following, within 10%:
            | Element | Instances |
            | 1       | 3800      |
            | 2       | 400       |
            | 3       | 500       |
            | 4       | 1200      |
            | 5       | 4100      |
