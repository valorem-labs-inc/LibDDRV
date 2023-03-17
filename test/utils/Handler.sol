// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {StdUtils} from "../../lib/forge-std/src/StdUtils.sol";
import {Vm} from "../../lib/forge-std/src/Vm.sol";

import {ContractUsingLib} from "./ContractUsingLib.sol";

contract Handler is StdUtils {
    mapping(bytes32 => uint256) public numCalls;

    ContractUsingLib public contractUsingLib;

    address[] internal accounts;
    address internal currentAccount;

    Vm private constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    modifier useRandomAccount(uint256 accountIndex) {
        currentAccount = accounts[bound(accountIndex, 0, accounts.length - 1)];

        vm.startPrank(currentAccount);
        _;
        vm.stopPrank();
    }

    constructor(address _contractUsingLib) {
        // Setup random accounts
        accounts.push(address(0xA1));
        accounts.push(address(0xA2));
        accounts.push(address(0xA3));
        accounts.push(address(0xA4));
        accounts.push(address(0xA5));
        accounts.push(address(0xA6));
        accounts.push(address(0xA7));
        accounts.push(address(0xA8));
        accounts.push(address(0xA9));
        accounts.push(address(0xA10));

        // Setup contract using LibDDRV
        contractUsingLib = ContractUsingLib(_contractUsingLib);
    }

    function preprocess(uint256[] memory weights, uint256 accountIndex) public useRandomAccount(accountIndex) {
        numCalls["preprocess"]++;
        contractUsingLib.preprocess(weights);
    }

    function insert_element(uint256 index, uint256 weight, uint256 accountIndex)
        public
        useRandomAccount(accountIndex)
    {
        numCalls["insert_element"]++;
        contractUsingLib.insert_element(index, weight);
    }

    function update_element(uint256 index, uint256 weight, uint256 accountIndex)
        public
        useRandomAccount(accountIndex)
    {
        numCalls["update_element"]++;
        contractUsingLib.update_element(index, weight);
    }

    function generate(uint256 index, uint256 seed, uint256 accountIndex)
        public
        useRandomAccount(accountIndex)
        returns (uint256)
    {
        numCalls["generate"]++;
        return contractUsingLib.generate(seed);
    }
}
