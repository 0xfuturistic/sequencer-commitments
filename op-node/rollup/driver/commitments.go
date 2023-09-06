package driver

import (
	"errors"

	"github.com/ethereum/go-ethereum/ethclient"

	"github.com/ethereum-optimism/optimism/op-bindings/bindings"
	"github.com/ethereum-optimism/optimism/op-service/eth"
)

func (s *Driver) validateCommitments(payload *eth.ExecutionPayload) error {
	// TODO: get L1 RPC URL passed in cmd
	client, err := ethclient.Dial("")
	if err != nil {
		return err
	}

	instance, err := bindings.NewSystemConfig(s.config.L1SystemConfigAddress, client)
	if err != nil {
		return err
	}

	var target [32]byte
	var value []byte

	// Sample assignment
	// TODO: decide on a target. maybe eip712 style?
	copy(target[:], "placeholder-target")
	// TODO: encode payload into bytes
	value = []byte("placeholder-value")

	satisfied, err := instance.ScreenProposer(nil, target, value)
	if err != nil {
		return err
	}

	if !satisfied {
		return errors.New("Failed_Screening")
	}

	s.log.Info("Commitments are satisfied", "target", target, "value", value)
	return nil
}
