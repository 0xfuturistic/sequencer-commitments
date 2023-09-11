# 🔴 OP Stack Sequencer Commitments

**A hack for the OP-Stack introducing EVM-programmed sequencer commitments.**

![Alt Text](first.gif)

Users that will become sequencers can enter into commitments in the EVM by leveraging [Emily](https://github.com/0xfuturistic/emily), a library for manging commitments in the EVM developed for [PEPC-DVT](https://ethresear.ch/t/pepc-dvt-pepc-with-no-changes-to-the-consensus-protocol/16514). This hack is a proof of concept for the OP-Stack, and it is not intended to be used in production.

## Why This Matters
This initiative bridges the capabilities of Layer 1 and Layer 2, ensuring sequencers can make, manage, and fulfill commitments, ultimately fostering transparency and reliability in transaction ordering.

## 🌟 Key Features
- **Dynamic Commitments**: Sequencers, as accounts, can initiate commitments in the L1.
- **L2 Reinforcement**: Commitments made by sequencers are enforced in L2, powered by a predetermined L1 contract.
- **Flexible Design**: Sequencers can make commitments even if they weren't conceived during L2 contract deployment.
- **Solidity Integration**: Commitments are anchored in L1 and stored as tuples of a function and a target, leveraging PEPC-DVT's model.

## 🛠  Potential Use Cases:

1. **Dynamic Transaction Integration**: Facilitate sequencer commitments for the inclusion of transactions with attributes defined after L2 deployment.
3. **Customized Transaction Ordering**: Empower L2 with programmable sequencing policies, offering tailored transaction processing patterns.
4. **MEV Mitigation Strategy**: Design strategies in Solidity to mitigate MEV by leveraging commitments to sequence transactions in a particular order.
5. **Versatile Contractual Commitments**: Design and deploy L1-L2 interoperable contracts, facilitating granular interaction between sequencers and third parties, backed by EVM-defined commitments.
6. **Front-Running Prevention**: Leveraging commitments to prevent front-running by committing to properties about the transaction inclusion order.
8. **Multi-Chain Atomic Swaps**: Facilitating atomic swaps by sequencing multi-step transactions in a particular order to ensure either successful swaps or no transaction at all.
9. **Commitments to Layered Prioritization**: Different categories of transactions (like urgent, premium, standard) can be sequenced based on their priorities.
10. **Fair Sequencing Services**: Introducing fairness in transaction ordering to minimize MEV and foster a more equitable transaction environment.


## ⚙ Technical Blueprint
**Harnessing Emily for Sequencer Commitments**

### Client's Perspective:
The `OnUnsafeL2Payload` function, at the heart of the client's stack, is responsible for assimilating new blocks. This is now integrated with the call to `n.validateCommitments(ctx, payload)`, ensuring every block respects its sequencer commitments. The logic for these commitments is implemented in the EVM by Emily.

**Insightful Code Snippets**:
```go
// In op-node/node/node.go
func (n *OpNode) OnUnsafeL2Payload(ctx context.Context, from peer.ID, payload *eth.ExecutionPayload) error {
    // Essential operations...

    // Commitments check
    if err := n.validateCommitments(ctx, payload); err != nil {
        return err
    }
    // Concluding operations...
}
```

```go
// Residing in op-node/node/pepc.go
func (n *OpNode) validateCommitments(ctx context.Context, payload *eth.ExecutionPayload) error {
    // Convert payload to bytecode
    payloadBytes, err := n.encodePayload(payload)
    if err != nil {
        return err
    }

    // Invoke the Screener
    satisfied, err := instance.Screen(nil, n.runCfg.P2PSequencerAddress(), *n.target(), payloadBytes)

    if err != nil {
        return err
    }
    if !satisfied {
        return errors.New("ScreeningFailed")
    }
}
```

### EVM's Role:
At the core of the EVM lies Emily's Screener contract, which allows for filtering payloads based on commitments. The `screen` function is responsible for checking whether the commitments of the sequencer are satisfied by the payload being screened. This is done by invoking the `areAccountCommitmentsSatisfiedByValue` function of the commitment manager, which is responsible for checking whether the commitments of the sequencer are satisfied by the value being written.

```solidity
contract Screener {
    /// @notice Checks if the account's commitments are satisfied by the value being written.
    /// @param account The account that is writing the value.
    /// @param target The target to which the value is being written.
    /// @param value The value being written.
    /// @return True if the account's commitments are satisfied by the value being written, false otherwise.
    function screen(address account, bytes32 target, bytes memory value) public view virtual returns (bool) {
        return commitmentManager.areAccountCommitmentsSatisfiedByValue(account, target, value, block.timestamp);
    }
}
```
It's important to note that even though they are constrained in their behavior by their commitment, a sequencer may choose not to provide their signature in the first place. So the sequencer can't be forced to act in a particular way. Rather, we prevent them from doing so in other ways, specifically those that would violate their commitments.

You can see the codebase for Emily [here](https://github.com/0xfuturistic/emily). As background, I recommend you check out [this Twitter thread](https://twitter.com/0xfuturistic/status/1697306608722915518) and the piece introducing [PEPC-DVT](https://ethresear.ch/t/pepc-dvt-pepc-with-no-changes-to-the-consensus-protocol/16514).

## 🗺 Road Ahead
- Expand the variety of commitments provided as a sample.
- Enhance and solidify the tests.
- Comprehensive documentation to accompany every feature, ensuring clarity.

## 🙌 Contribute & Feedback
Your insights can shape the future of this initiative. Feel free to [raise an issue](#), suggest a feature, or even fork the repository for personal tweaks.

## 📜 License
This project is licensed under the MIT License. For more details, please see [LICENSE file](#).
