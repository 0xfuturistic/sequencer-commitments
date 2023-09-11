// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { stdError } from "forge-std/Test.sol";
import { L2OutputOracle_Initializer } from "./CommonTest.t.sol";
import { FeeRecipientCommitment, CommitmentBase } from "../src/commitments/samples/FeeRecipientCommitment.sol";

contract FeeRecipientCommitment_Test is L2OutputOracle_Initializer {
    FeeRecipientCommitment public commitment;

    function setUp() public override {
        super.setUp();
        commitment = new FeeRecipientCommitment(oracle);
    }

    function test_setNewFeeRecipient(address feeRecipient, uint64 blockNumber) public {
        vm.prank(oracle.PROPOSER());
        commitment.setNewFeeRecipient(feeRecipient, blockNumber);
        assertEq(commitment.feeRecipientSet(oracle.PROPOSER(), blockNumber), feeRecipient);
    }

    function test_commitmentIndicatorFun(address feeRecipient, uint64 blockNumber) public {
        CommitmentBase.ExecutionPayload memory executionPayload = CommitmentBase.ExecutionPayload(
            bytes32(0),
            feeRecipient,
            bytes32(0),
            bytes32(0),
            bytes(""),
            bytes32(0),
            blockNumber,
            uint64(0),
            uint64(0),
            uint64(0),
            bytes(""),
            bytes32(0),
            bytes32(0),
            bytes("")
        );

        bytes memory encodedPayload = abi.encode(executionPayload);

        if (
            commitment.feeRecipientIsSet(oracle.PROPOSER(), blockNumber)
                && feeRecipient != commitment.feeRecipientSet(oracle.PROPOSER(), blockNumber)
        ) {
            assertEq(commitment.commitmentIndicatorFun(encodedPayload), 0);
        } else {
            assertEq(commitment.commitmentIndicatorFun(encodedPayload), 1);
        }
    }

    function test_flow(address feeRecipient, uint64 blockNumber) public {
        test_setNewFeeRecipient(feeRecipient, blockNumber);
        test_commitmentIndicatorFun(feeRecipient, blockNumber);
    }
}
