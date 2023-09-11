// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { stdError } from "forge-std/Test.sol";
import { L2OutputOracle_Initializer, NextImpl } from "./CommonTest.t.sol";
import { L2OutputOracle } from "../src/L1/L2OutputOracle.sol";
import { CommitmentManager } from "emily/CommitmentManager.sol";
import { FeeRecipientCommitment } from "../src/commitments/samples/FeeRecipientCommitment.sol";

contract L2OutputOracle_constructor_Test is L2OutputOracle_Initializer {
    FeeRecipientCommitment public commitment;

    function setUp() public override {
        super.setUp();
        commitment = new FeeRecipientCommitment(oracle);
    }
}
