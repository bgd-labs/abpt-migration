// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {EthereumScript} from 'aave-helpers/ScriptUtils.sol';
import {ProposalPayload} from '../src/contracts/ProposalPayload.sol';

/**
 * @notice Deploys a the proposalPayload
 * deploy-command: make deploy-ledger contract=scripts/02_DeployPayload.sol:DeployPayload chain=mainnet
 */
contract DeployPayload is EthereumScript {
  function _deploy() public returns (address) {
    return
      address(
        new ProposalPayload(
          0x1401bf602d95a0d52978961644B7BDD117Cf6Df6,
          0x9eDA81C21C273a82BE9Bbc19B6A6182212068101
        )
      );
  }

  function run() external broadcast {
    _deploy();
  }
}
