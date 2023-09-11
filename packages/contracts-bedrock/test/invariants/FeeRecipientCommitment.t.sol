// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { Test } from "forge-std/Test.sol";
import { CommonBase } from "forge-std/Base.sol";
import { StdCheats } from "forge-std/StdCheats.sol";
import { StdUtils } from "forge-std/StdUtils.sol";
import { console } from "forge-std/console.sol";
import { FeeRecipientCommitment, CommitmentBase } from "../../src/commitments/samples/FeeRecipientCommitment.sol";
import { L2OutputOracle_Initializer } from "../CommonTest.t.sol";

contract FeeRecipientCommitment_Handler is CommonBase, StdCheats, StdUtils {
    FeeRecipientCommitment public commitment;

    bytes public ghost_rawPayload;
    uint256 public ghost_indicatorOutput;

    mapping(bytes32 => uint256) public calls;
    address[] internal actors;
    address public currentActor;

    modifier countCall(bytes32 key) {
        calls[key]++;
        _;
    }

    modifier createActor() {
        currentActor = msg.sender;
        actors.push(msg.sender);
        _;
    }

    modifier useActor(uint256 actorIndexSeed) {
        currentActor = actors[bound(actorIndexSeed, 0, actors.length - 1)];
        vm.startPrank(currentActor);
        _;
        vm.stopPrank();
    }

    constructor(FeeRecipientCommitment commitment_) {
        commitment = commitment_;
    }

    function setNewFeeRecipient(
        address feeRecipient,
        uint64 blockNumber
    )
        external
        createActor
        countCall("setNewFeeRecipient")
    {
        commitment.setNewFeeRecipient(feeRecipient, blockNumber);
    }

    function commitmentIndicatorFun(
        uint256 actorIndexSeed,
        bytes memory rawPayload
    )
        external
        useActor(actorIndexSeed)
        countCall("commitmentIndicatorFun")
    {
        ghost_rawPayload = rawPayload;
        ghost_indicatorOutput = commitment.commitmentIndicatorFun(rawPayload);
    }

    function callSummary() external view {
        console.log("Call summary:");
        console.log("-------------------");
        console.log("setNewFeeRecipient", calls["setNewFeeRecipient"]);
        console.log("commitmentIndicatorFun", calls["commitmentIndicatorFun"]);
        console.log("-------------------");
    }
}

contract FeeRecipientCommitment_Invariants is L2OutputOracle_Initializer {
    FeeRecipientCommitment public commitment;
    FeeRecipientCommitment_Handler public handler;

    function setUp() public override {
        super.setUp();
        commitment = new FeeRecipientCommitment(oracle);
        handler = new FeeRecipientCommitment_Handler(commitment);

        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = handler.setNewFeeRecipient.selector;
        selectors[1] = handler.commitmentIndicatorFun.selector;

        targetSelector(FuzzSelector({ addr: address(handler), selectors: selectors }));
        targetContract(address(handler));
    }

    function invariant_commitmentIndicatorFun() public {
        uint256 indicatorOutput = handler.ghost_indicatorOutput();
        bytes memory rawPayload = handler.ghost_rawPayload();

        if (rawPayload.length > 0) {
            CommitmentBase.ExecutionPayload memory payload = abi.decode(rawPayload, (CommitmentBase.ExecutionPayload));

            if (
                commitment.feeRecipientIsSet(handler.currentActor(), payload.BlockNumber)
                    && payload.FeeRecipient != commitment.feeRecipientSet(handler.currentActor(), payload.BlockNumber)
            ) {
                assertEq(indicatorOutput, 0);
            } else {
                assertEq(indicatorOutput, 1);
            }
        }
    }

    function invariant_callSummary() public view {
        handler.callSummary();
    }
}
