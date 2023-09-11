package node

import (
	"bytes"
	"context"
	"errors"

	"github.com/ethereum-optimism/optimism/op-bindings/bindings"
	"github.com/ethereum-optimism/optimism/op-service/eth"
	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/common/hexutil"
)

// validateCommitments validates that the proposer's commitments are satisfied for the given payload.
// It does this by passing the payload to the L1 SystemConfig contracts, which checks the commitments.
// It returns an error if the commitments are not satisfied.
func (n *OpNode) validateCommitments(ctx context.Context, payload *eth.ExecutionPayload) error {
	instance, err := bindings.NewSystemConfig(n.runCfg.rollupCfg.L1SystemConfigAddress, n.l1Source.EthClient)
	if err != nil {
		return err
	}

	// Encoding payload
	payloadBytes, err := n.encodePayload(payload)
	if err != nil {
		return err
	}

	// Calling Screen function
	satisfied, err := instance.Screen(nil, n.runCfg.P2PSequencerAddress(), *n.target(), payloadBytes)
	if err != nil {
		return err
	}
	if !satisfied {
		return errors.New("Failed_Screening")
	}

	n.log.Info("Commitments are satisfied for payload", "account", n.runCfg.P2PSequencerAddress(), "target", string(n.target()[:]))
	return nil
}

func (n *OpNode) target() *[32]byte {
	var target [32]byte
	copy(target[:], common.Hex2BytesFixed("0x0000000000000000000000000000000000000000000000000000000000000000", 32))
	return &target
}

func (n *OpNode) encodePayload(payload *eth.ExecutionPayload) ([]byte, error) {
	var (
		structExecutionPayload, _ = abi.NewType("tuple", "struct ExecutionPayload", []abi.ArgumentMarshaling{
			{Name: "ParentHash", Type: "bytes32"},
			{Name: "FeeRecipient", Type: "address"},
			{Name: "StateRoot", Type: "bytes32"},
			{Name: "ReceiptsRoot", Type: "bytes32"},
			{Name: "LogsBloom", Type: "bytes"},
			{Name: "PrevRandao", Type: "bytes32"},
			{Name: "BlockNumber", Type: "uint64"},
			{Name: "GasLimit", Type: "uint64"},
			{Name: "GasUsed", Type: "uint64"},
			{Name: "Timestamp", Type: "uint64"},
			{Name: "ExtraData", Type: "bytes"},
			{Name: "BaseFeePerGas", Type: "bytes32"},
			{Name: "BlockHash", Type: "bytes32"},
			{Name: "Transactions", Type: "bytes"},
		})

		args = abi.Arguments{
			{Type: structExecutionPayload, Name: "param_one"},
		}
	)

	_payload := struct {
		ParentHash    common.Hash
		FeeRecipient  common.Address
		StateRoot     [32]byte
		ReceiptsRoot  [32]byte
		LogsBloom     []byte
		PrevRandao    [32]byte
		BlockNumber   hexutil.Uint64
		GasLimit      hexutil.Uint64
		GasUsed       hexutil.Uint64
		Timestamp     hexutil.Uint64
		ExtraData     []byte
		BaseFeePerGas [32]byte
		BlockHash     common.Hash
		Transactions  []byte
	}{
		payload.ParentHash,
		payload.FeeRecipient,
		payload.StateRoot,
		payload.ReceiptsRoot,
		[]byte(payload.LogsBloom.String()),
		payload.PrevRandao,
		payload.BlockNumber,
		payload.GasLimit,
		payload.GasUsed,
		payload.Timestamp,
		payload.ExtraData,
		payload.BaseFeePerGas.Bytes32(),
		payload.BlockHash,
		encodeTransactions(payload.Transactions),
	}

	packed, err := args.Pack(&_payload)
	if err != nil {
		return nil, err
	}
	return packed, nil
}

func encodeTransactions(txs []eth.Data) []byte {
	var res [][]byte
	for _, v := range txs {
		res = append(res, v)
	}

	return bytes.Join(res, nil)
}
