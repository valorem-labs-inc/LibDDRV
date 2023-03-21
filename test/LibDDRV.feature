Feature: Dynamic Discrete Random Variate Generation

    As a Solidity Developer,
    I want to generate random variates from a discrete distribution of dynamically weighted elements in sublinear time,
    so that I can make probabilistic selections in my smart contracts.

    # Preprocess

    Scenario: Preprocess 0 Elements

    Scenario: Preprocess 1 Element

    Scenario: Preprocess 10 Elements

    Scenario: Preprocess 100 Elements

    # Insert

    Scenario: Insert 1 Element

    Scenario: Insert 1 Element 10 times

    Scenario: Insert 1 Element 100 times

    # Update

    #*//////////////////////////////////////////////////////////////
    #
    #   Background Visual Representation of Forest
    #
    #                  R₆⁽²⁾                R₅⁽²⁾
    #                   |                    |
    #                   |                    |
    #                   |                    |
    #    R₅⁽¹⁾         R₄⁽¹⁾                R₃⁽¹⁾
    #     |         / / |  \ \           / / |  \ \
    #     |       /  |  |  |  \        /  |  |  |  \
    #     |      /   |  |  |   \      /   |  |  |   \
    #     4     11  10  9  3   1     8   7   6  5   2
    #
    #/////////////////////////////////////////////////////////////*/

    Background: Forest with 11 Elements, 3 Root Ranges, 2 Levels, and total weight of 100
        # (applies only to Update scenarios)
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

    Scenario: A -- Update 1 Element, no change in weight, no change in parent
        When I update Element 8 from weight 5 to weight 5
        Then The parent of Element 8 should still be R₃⁽¹⁾
        And There should be no change the total weight, Levels, or structure of the Forest

    Scenario: B -- Update 1 Element, decrease weight, no change in parent
        When I update Element 8 from weight 5 to weight 4
        Then The parent of Element 8 should still be R₃⁽¹⁾
        And The total weight of the Forest should be 99
        And There should be 2 Levels in the Forest
        And The weight of Level 1 should be 20
        And The weight of Level 2 should be 79
        And The weight of R₅⁽²⁾ should be 24
        And The weight of R₆⁽²⁾ should be 55
        And The Forest should not change its structure

    Scenario: C -- Update 1 Element, decrease weight, moves to lower range numbered-parent
        When I update Element 3 from weight 15 to weight 6
        Then The parent of Element 3 should now be R₃⁽¹⁾
        And The total weight of the Forest should be 91
        And There should be 2 Levels in the Forest
        And The weight of Level 1 should be 20
        And The weight of Level 2 should be 71
        And The weight of R₅⁽²⁾ should be 31
        And The weight of R₆⁽²⁾ should be 40
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
        Then The parent of Element 8 should still be R₃⁽¹⁾
        And The total weight of the forest should be 102
        And There should be 2 Levels in the Forest
        And The weight of Level 1 should be 20
        And The weight of Level 2 should be 82
        And The weight of R₅⁽²⁾ should be 27
        And The weight of R₆⁽²⁾ should be 55
        And The Forest should not change its structure

    Scenario: E -- Update 1 Element, increase weight, moves to higher range numbered-parent
        When I update Element 8 from weight 5 to weight 8
        Then The parent of Element 8 should now be R₄⁽¹⁾
        And The total weight of the forest should be 103
        And There should be 2 Levels in the Forest
        And The weight of Level 1 should be 20
        And The weight of Level 2 should be 83
        And The weight of R₅⁽²⁾ should be 20
        And The weight of R₆⁽²⁾ should be 63
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
        Then The parent of Element 3 should now be R₃⁽¹⁾
        And The parent of R₃⁽¹⁾ should now be R₆⁽²⁾
        And The total weight of the forest should be 92
        And There should be 3 Levels in the Forest
        And The weight of Level 1 should be 20
        And The weight of Level 2 should be 0
        And The weight of Level 3 should be 72
        And The weight of R₆⁽³⁾ should be 72
        And The Forest should have the following structure:
            | Element | E Weight | Parent | P Weight | Grandparent | GP Weight | Greatgrandparent | GGP Weight |
            | 2       | 5        | R₃⁽¹⁾  | (32)     | R₆⁽²⁾       | (72)      | R₆⁽³⁾            | 72         |
            | 3       | 7 *      | R₃⁽¹⁾  | (32)     | R₆⁽²⁾       | (72)      | R₆⁽³⁾            | 72         |
            | 5       | 5        | R₃⁽¹⁾  | (32)     | R₆⁽²⁾       | (72)      | R₆⁽³⁾            | 72         |
            | 6       | 5        | R₃⁽¹⁾  | (32)     | R₆⁽²⁾       | (72)      | R₆⁽³⁾            | 72         |
            | 7       | 5        | R₃⁽¹⁾  | (32)     | R₆⁽²⁾       | (72)      | R₆⁽³⁾            | 72         |
            | 8       | 5        | R₃⁽¹⁾  | (32)     | R₆⁽²⁾       | (72)      | R₆⁽³⁾            | 72         |
            | 1       | 10       | R₄⁽¹⁾  | (40)     | R₆⁽²⁾       | (72)      | R₆⁽³⁾            | 72         |
            | 9       | 10       | R₄⁽¹⁾  | (40)     | R₆⁽²⁾       | (72)      | R₆⁽³⁾            | 72         |
            | 10      | 10       | R₄⁽¹⁾  | (40)     | R₆⁽²⁾       | (72)      | R₆⁽³⁾            | 72         |
            | 11      | 10       | R₄⁽¹⁾  | (40)     | R₆⁽²⁾       | (72)      | R₆⁽³⁾            | 72         |
            | 4       | 20       | R₅⁽¹⁾  | 20       |             |           |                  |            |

    Scenario: G -- Update 1 Element, increase weight, moves to higher range numbered-parent and -grandparent
        When I update Element 8 from weight 5 to weight 9
        Then The parent of Element 3 should now be R₄⁽¹⁾
        And The parent of R₄⁽¹⁾ should now be R₇⁽²⁾
        And The total weight of the forest should be 104
        And There should be 2 Levels in the Forest
        And The weight of Level 1 should be 20
        And The weight of Level 2 should be 84
        And The weight of R₅⁽²⁾ should be 20
        And The weight of R₇⁽²⁾ should be 64
        Then The Forest should have the following structure:
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

    Scenario: H -- Update 1 Element, decrease weight, moves to lower range numbered-grandparent, no change in parent

    Scenario: I -- Update 1 Element, increase weight, moves to higher range numbered-grandparent, no change in parent

    Scenario: J -- Update 1 Element, increase weight, moves to much higher range numbered-parent and -grandparent

    Scenario: K -- Update 4 Elements, 1 parent dies

    Scenario: L -- Update 4 Elements, 1 grandparent dies

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
