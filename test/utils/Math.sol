// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// TODO
library Math {
    /*//////////////////////////////////////////////////////////////
    // Arithmetic
    //////////////////////////////////////////////////////////////*/

    /// TODO
    function add(uint256 x, uint256 y) public pure returns (uint256 result) {
        // TODO
    }

    /// TODO
    function sub(uint256 x, uint256 y) public pure returns (uint256 result) {
        // TODO
    }

    /// TODO
    function mul(uint256 x, uint256 y) public pure returns (uint256 result) {
        // TODO
    }

    /// TODO
    function div(uint256 x, uint256 y) public pure returns (uint256 result) {
        // TODO
    }

    /*//////////////////////////////////////////////////////////////
    // Exponents
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Exponentiate 2 to the power of x.
     * @dev tbd
     * @param x The input value.
     * @return result 2 to the power of x.
     */
    function pow2(uint256 x) public pure returns (uint256 result) {
        // TODO not sure we need
    }

    /**
     * @notice Calculate the base-2 "power tower" of order x, with hat m.
     * @dev A power tower of order 3 with hat 5 is equivalent to 2^2^2^5. A power tower
     * of order 5 with hat 6 is equivalent to 2^2^2^2^2^6. Supports up to TODO order.
     * @param x The number of times to iteratively exponentiate 2 to the power of 2.
     * @param m The final exponent in the power tower.
     * @return result The base-2 power tower of order x with hat m.
     */
    function powerTower2(uint256 x, uint256 m) public pure returns (uint256 result) {
        // TODO
    }

    /*//////////////////////////////////////////////////////////////
    // Logarithms
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Calculate the base-2 logarithm.
     * @dev tbd
     * @param x The input value.
     * @return result The base-2 logarithm of x.
     */
    function log2(uint256 x) public pure returns (uint256 result) {
        // TODO
    }

    /**
     * @notice Calculate the base-2 iterated logarithm.
     * @dev tbd
     * @param x The input value.
     * @return result The iterative base-2 logarithm of x.
     */
    function logStar2(uint256 x) public pure returns (uint256 result) {
        // TODO
    }

    /// TODO
    function log10(uint256 x) public pure returns (uint256 result) {
        // TODO
    }

    /*//////////////////////////////////////////////////////////////
    // Rounding
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Round down to the nearest integer.
     * @dev tbd
     * @param x The input value.
     * @return result The value of x rounded down to the nearest integer.
     */
    function floor(uint256 x) public pure returns (uint256 result) {
        // TODO
    }

    /**
     * @notice Round up to the nearest integer.
     * @dev tbd
     * @param x The input value.
     * @return result The value of x rounded up to the nearest integer.
     */
    function ceiling(uint256 x) public pure returns (uint256 result) {
        // TODO
    }
}
