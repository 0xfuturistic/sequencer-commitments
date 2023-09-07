package node

import (
	"context"
	"errors"

	"github.com/ethereum-optimism/optimism/op-bindings/bindings"
	"github.com/ethereum-optimism/optimism/op-service/eth"
	"github.com/ethereum/go-ethereum/ethclient"
)

// validateCommitments validates that the proposer's commitments are satisfied for the given payload.
// It does this by passing the payload to the L1 SystemConfig contracts, which checks the commitments.
// It returns an error if the commitments are not satisfied.
func (n *OpNode) validateCommitments(ctx context.Context, payload *eth.ExecutionPayload) error {
	client, err := ethclient.Dial("")
	if err != nil {
		return err
	}

	instance, err := bindings.NewSystemConfig(n.runCfg.rollupCfg.L1SystemConfigAddress, client)
	if err != nil {
		return err
	}

	satisfied, err := instance.ScreenProposer(nil, target(), payloadBytes(payload))
	if err != nil {
		return err
	}

	if !satisfied {
		return errors.New("Failed_Screening")
	}

	n.log.Info("Commitments are satisfied")
	return nil
}

func target() [32]byte {
	var target [32]byte
	copy(target[:], "placeholder-target")
	return target
}

func payloadBytes(payload *eth.ExecutionPayload) []byte {
	return []byte("placeholder-value")
}
