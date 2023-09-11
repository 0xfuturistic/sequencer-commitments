// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { CommitmentBase } from "../CommitmentBase.sol";
import { L2OutputOracle } from "../../L1/L2OutputOracle.sol";

contract FeeRecipientCommitment is CommitmentBase {
    mapping(address => mapping(uint256 => bool)) public feeRecipientIsSet;
    mapping(address => mapping(uint256 => address)) public feeRecipientSet;

    event NewFeeRecipientSet(address sequencer, address feeRecipient, uint64 blockNumber);

    constructor(L2OutputOracle l2OutputOracle_) CommitmentBase(l2OutputOracle_) { }

    function setNewFeeRecipient(address feeRecipient, uint64 blockNumber) external {
        require(!feeRecipientIsSet[msg.sender][blockNumber], "Fee recipient already set");
        feeRecipientIsSet[msg.sender][blockNumber] = true;
        feeRecipientSet[msg.sender][blockNumber] = feeRecipient;
        emit NewFeeRecipientSet(msg.sender, feeRecipient, blockNumber);
    }

    function commitmentIndicatorFun(bytes memory rawPayload) external view returns (uint256) {
        // get sequencer from l2OutputOracle, just like in op-node
        address sequencer = l2OutputOracle.PROPOSER();
        // decode payload
        (ExecutionPayload memory executionPayload) = abi.decode(rawPayload, (ExecutionPayload));
        // get fields from payload
        uint64 blockNumber = executionPayload.BlockNumber;
        address payloadFeeRecipient = executionPayload.FeeRecipient;
        // check if fee recipient is the same as the one committed by the sequencer, if any
        if (
            !feeRecipientIsSet[sequencer][blockNumber] || payloadFeeRecipient == feeRecipientSet[sequencer][blockNumber]
        ) {
            return 1;
        } else {
            return 0;
        }
    }
}
