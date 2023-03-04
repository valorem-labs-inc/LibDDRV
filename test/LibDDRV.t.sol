// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "src/LibDDRV.sol";

contract TestDDRV is Test {
    Forest internal test_forest;

    function test_preprocess() public {
        uint256[] memory weights = new uint256[](3);
        weights[0] = 1;
        weights[1] = 75;
        weights[2] = 12;

        LibDDRV.preprocess(weights, test_forest);
    }
}
