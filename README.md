# 🔴 OP Stack Sequencer Commitments

**A hack for the OP Stack introducing sequencer commitments.**

![Alt Text](cover.gif)

Users that will become sequencers can enter into commitments in the EVM by leveraging [Emily](https://github.com/0xfuturistic/emily), a library for managing commitments on-chain developed for [PEPC-DVT](https://ethresear.ch/t/pepc-dvt-pepc-with-no-changes-to-the-consensus-protocol/16514). This hack is a proof of concept for the [OP Stack](https://stack.optimism.io/), and it is not intended to be used in production.

## Why This Matters
As L2s gain momentum, sequencers' capacity to establish credible commitments becomes ever more important. This not only enhances transparency in transaction ordering but also holds the potential for versatile, general-purpose contracting with the sequencer as the counterparty.

## Background Readings
 I recommend checking out this [thread](https://twitter.com/0xfuturistic/status/1697306608722915518) and the article introducing [PEPC-DVT](https://ethresear.ch/t/pepc-dvt-pepc-with-no-changes-to-the-consensus-protocol/16514).

 A [sample commitment](https://github.com/0xfuturistic/sequencer-commitments/blob/develop/packages/contracts-bedrock/src/commitments/samples/FeeRecipientCommitment.sol) is included, which allows the sequencer to commit to fee recipients for specific blocks.

## 🌟 Key Features
- **Dynamic Commitments**: Sequencers, as accounts, can enter into commitments in the L1.
- **L2 Enforcement**: Commitments made by sequencers are enforced on L2 blocks, with the logic outsourced to a a predetermined L1 contract.
- **Flexible Design**: Sequencers can make commitments even if they weren't conceived during L2 contract deployment. Because of the EVM, commitments as programs are Turing-complete and can rely on any on-chain data.
- **Solidity Integration**: Commitments are anchored in L1 and stored as tuples of a function and a target, leveraging PEPC-DVT's model. This allows for commitments to be defined in Solidity, and for the EVM to be used as a commitment manager.

## 🛠  Potential Use Cases:

1. **Customized Transaction Ordering**: Empower L2 with programmable sequencing policies, offering tailored transaction processing patterns.
2. **MEV Mitigation**: Design strategies in Solidity to mitigate MEV by leveraging commitments to sequence transactions in a particular way.
3. **General-purpose Contracts**: Design and deploy L1-L2 interoperable contracts, facilitating granular interaction between sequencers and third parties, backed by EVM-defined commitments.
4. **Front-Running Prevention**: Leveraging commitments to prevent front-running by committing to including a transaction as the first in the block or with only some specific transactions before it.
5. **Multi-Chain Atomic Operations**: Facilitating atomic operations by sequencing multi-step transactions in a particular order to ensure either successful operations or no transaction at all.
6. **Commitments to Layered Prioritization**: Different categories of transactions (like urgent, premium, standard) can be sequenced based on their priorities.
7. **_Sequencing Services_**: Introducing features such as fairness in transaction ordering to minimize MEV and foster a more equitable transaction environment.

## ⚙ Technical Blueprint
### In the Rollup Client
The `OnUnsafeL2Payload` function, at the heart of the client's stack (`op-node`), is responsible for processing new payloads. This function now integrates a call that validates payloads for commitment satisfaction. The logic for these commitments is implemented in the EVM by Emily.

```go
// In op-node/node/node.go
func (n *OpNode) OnUnsafeL2Payload(ctx context.Context, from peer.ID, payload *eth.ExecutionPayload) error {
    ...
    // Commitments check
    if err := n.validateCommitments(ctx, payload); err != nil {
        return err
    }
    ...
}
```

```go
// In op-node/node/pepc.go
func (n *OpNode) validateCommitments(ctx context.Context, payload *eth.ExecutionPayload) error {
    ...
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

### In the L1
Leveraging Emily's [Screener contract](https://github.com/0xfuturistic/emily/blob/main/src/Screener.sol), we filter the payloads that don't satisfy the sequencer's commitments. The rollup's system config inherits from this contract and implements a `screen` function responsible for checking whether the commitments of the sequencer are satisfied by the payload being screened. Screener does this by invoking the `areAccountCommitmentsSatisfiedByValue` function of a [CommitmentManager contract](https://github.com/0xfuturistic/emily/blob/main/src/CommitmentManager.sol), which is responsible for storing and managing commitments.

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
It's also worth noting that even though they are constrained in their behavior by their commitments, a sequencer may choose not to provide their signature in the first place. So the sequencer can't be forced to act in a particular way. Rather, we prevent them from doing so in specific ways (i.e., in ways that violate their commitments).

```mermaid
sequenceDiagram
		participant Network
		participant OP-Node
		participant L1 SystemConfig
		participant CommitmentManager

		Network-)OP-Node: OnUnsafeL2Payload
		note right of Network: A new payload is received
		critical Validate payload satisfies all commitments
				note over L1 SystemConfig: inherits from Screener
				OP-Node->>L1 SystemConfig: screen
				note right of OP-Node: target is a series of bytes <br> identifying rollup
						L1 SystemConfig->>CommitmentManager: areAccountCommitmmentsSatisfiedByValue
						CommitmentManager->CommitmentManager: get sequencer's commitments for target
						loop For each commitment
								CommitmentManager-->CommitmentManager: check commitment is satisfied
						end
		option Payload satisfies all commitments
				CommitmentManager->>OP-Node: return true
				OP-Node-->OP-Node: continue processing payload
		option Payload doesn't satisfy a commitment
				CommitmentManager->>OP-Node: return false
				OP-Node-->OP-Node: reject payload
		end
```

## 🗺 Road Ahead
- Expand the variety of commitments provided as a sample.
- Enhance and solidify the tests.
- Comprehensive documentation to accompany every feature.

## 🙌 Contribute & Feedback
Your insights can shape the future of this initiative. Feel free to [raise an issue](https://github.com/0xfuturistic/sequencer-commitments/issues/new), suggest a feature, or even fork the repository for personal tweaks. If you'd like to contribute, please fork the repository and make changes as you'd like. Pull requests are warmly welcome.

For questions and feedback, you can also reach out via [Twitter](https://twitter.com/0xfuturistic/).

## 📜 License
This project is licensed under the MIT License. For more details, please see [LICENSE file](https://github.com/0xfuturistic/sequencer-commitments/blob/develop/LICENSE).
