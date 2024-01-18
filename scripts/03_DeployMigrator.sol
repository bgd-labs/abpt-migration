// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {EthereumScript} from 'aave-helpers/ScriptUtils.sol';
import {StkABPTMigrator} from '../src/contracts/StkABPTMigrator.sol';

/**
 * @notice Deploys a the proposalPayload
 * deploy-command: make deploy-ledger contract=scripts/03_DeployMigrator.sol:DeployMigrator chain=mainnet
 */
contract DeployMigrator is EthereumScript {
  function _deploy() public returns (address) {
    return address(new StkABPTMigrator(0x9eDA81C21C273a82BE9Bbc19B6A6182212068101));
  }

  function run() external broadcast {
    _deploy();
  }
}
