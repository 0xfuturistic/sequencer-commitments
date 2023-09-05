// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {CommitmentManager as Manager} from "emily/CommitmentManager.sol";

contract CommitmentManager is Manager {
    constructor(uint256 accountCommitmentsGasLimit) Manager(accountCommitmentsGasLimit) {}
}
