// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { L2OutputOracle } from "../L1/L2OutputOracle.sol";

contract CommitmentBase {
    struct ExecutionPayload {
        bytes32 ParentHash;
        address FeeRecipient;
        bytes32 StateRoot;
        bytes32 ReceiptsRoot;
        bytes LogsBloom;
        bytes32 PrevRandao;
        uint64 BlockNumber;
        uint64 GasLimit;
        uint64 GasUsed;
        uint64 Timestamp;
        bytes ExtraData;
        bytes32 BaseFeePerGas;
        bytes32 BlockHash;
        bytes Transactions;
    }

    L2OutputOracle public l2OutputOracle;

    constructor(L2OutputOracle l2OutputOracle_) {
        l2OutputOracle = l2OutputOracle_;
    }
}
