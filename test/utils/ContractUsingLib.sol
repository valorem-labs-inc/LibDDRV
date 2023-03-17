// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../../src/LibDDRV.sol";

contract ContractUsingLib {
    uint256 public numberOfElements;
    uint256 public numberOfLevels;
    uint256 public numberOfRanges;

    Forest internal forest;

    function preprocess(uint256[] memory weights) public {
        LibDDRV.preprocess(weights, forest);
    }

    function insert_element(uint256 index, uint256 weight) public {
        LibDDRV.insert_element(index, weight, forest);
    }

    function update_element(uint256 index, uint256 weight) public {
        LibDDRV.update_element(index, weight, forest);
    }

    function generate(uint256 seed) public returns (uint256) {
        return LibDDRV.generate(forest, seed);
    }
}
