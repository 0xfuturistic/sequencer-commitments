#OP Stack _Sequencer Commitments_

**A hack for the OP-Stack introducing sophisticated sequencer commitments.**

Users that will become sequencers can enter into commitments in the EVM by using Emily, a library for manging commitments in the EVM developed for PEPC. This hack is a proof of concept for the OP-Stack, and it is not intended to be used in production.

## Why This Matters
This initiative bridges the capabilities of Layer 1 and Layer 2, ensuring sequencers can make, manage, and fulfill commitments, ultimately fostering transparency and reliability in transaction ordering.

## 🌟 Key Features
- **Dynamic Commitments**: Both user accounts and sequencers can initiate commitments in the L1 ecosystem.
- **L2 Reinforcement**: Commitments made by sequencers are enforced in L2, powered by a predetermined L1 contract.
- **Flexible Design**: Sequencers can make commitments even if they weren't conceived during L1 contract deployment.
- **Solidity Integration**: Commitments are anchored in L1 and visualized using Solidity's robust functions and targets.

## 🛠 Use Cases
1. **Dynamic Transaction Commitments**: Pledge to include transactions, even with properties not defined at the L1 contract launch.
2. **Exclusion Commitments**: Promise not to incorporate specific transactions.
3. **Programmable Policies**: Design custom transaction ordering rules within L2.
4. **MEV Mitigation**: Deploy strategies in the EVM to mitigate Miner Extractable Value (MEV).
5. **Contract Versatility**: Design general-purpose contracts between sequencers and external entities with satisfaction rules, all within the EVM.
6. **Anti-Front Running Commitments**:
7. Commitments to Off-Peak Transaction Processing:
8. Front-Running Prevention
Leveraging commitments to prevent front-running by fixing the transaction inclusion order, thereby precluding sequencers from exploiting user transactions based on privileged information.
Technical Details: Utilizing commitments to establish a specific transaction ordering that is publicly known. The sequencer verifies these commitments through smart contracts in EVM before signing the block
9. Atomic Swaps: Description: Facilitating atomic swaps by sequencing multi-step transactions in a particular order to ensure either successful swaps or no transaction at all.
10. "Fair Sequencing Services": Description: Introducing fairness in transaction ordering to minimize MEV and foster a more equitable transaction environment.
11. Commitments to Layered Prioritization: Different categories of transactions (like urgent, premium, standard) can be sequenced based on their priorities.
Technical Detail: The sequencer's commitment would involve parsing the transaction type or attached metadata and ensuring that higher-priority transactions are sequenced ahead of others.
12.

## ⚙ Technical Blueprint
**Harnessing Emily for Sequencer Commitments**

### Client's Perspective:
The `OnUnsafeL2Payload` function, at the heart of the client's stack, is responsible for assimilating new blocks. This is now integrated with the call to `n.validateCommitments(ctx, payload)`, ensuring every block respects its sequencer commitments. All of these are brought to life in the EVM with Emily's prowess.

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
At the core of the EVM lies Emily's Screener contract, a guardian ensuring commitments are upheld.

```solidity
contract Screener {
    // Contract variables...
    function screen(address account, bytes32 target, bytes memory value) public view virtual returns (bool) {
        return commitmentManager.areAccountCommitmentsSatisfiedByValue(account, target, value, block.timestamp);
    }
}
```
It's important to note that the sequencer even though is constrained in their behavior by the commitment may choose not to provide their signature in the first place. So the sequencer can't be forced to act in a particular way. Rather, we prevent them from doing taking certain actions by rejecting their payloads when they don't respect their commitments.

For a dive into the depths of the Emily library, please [explore this comprehensive guide](#). For those intrigued by the theoretical underpinnings, this [scholarly resource](#) is a treasure trove.

## 🗺 Road Ahead
- Expand the variety of commitments within the EVM.
- Enhance and solidify the test framework.
- Comprehensive documentation to accompany every feature, ensuring clarity.

## 🚀 Getting Started
For those eager to dive into the world of sequencer commitments, our [Quick Start Guide](#) is the perfect launchpad. It provides a step-by-step walkthrough, from installation to your first commitment!

## 🙌 Contribute & Feedback
Your insights can shape the future of this initiative. Feel free to [raise an issue](#), suggest a feature, or even fork the repository for personal tweaks. We thrive on collaborative brilliance!

## 📜 License
This project is licensed under the MIT License. For more details, please see our [LICENSE file](#).

## 🙏 Acknowledgments
A big shout-out to our collaborators, supporters, and the Ethereum community for their unwavering encouragement and invaluable feedback. Special thanks to the teams behind Solidity and Ethereum for their pioneering work.

---

Thank you for your interest in our project. Together, we're building the next chapter in Ethereum's L2 narrative.