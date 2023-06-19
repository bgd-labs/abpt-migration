// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {EthereumScript} from 'aave-helpers/ScriptUtils.sol';
import {ProposalPayload} from '../src/contracts/ProposalPayload.sol';

/**
 * @notice Deploys a the proposalPayload
 */
contract DeployPayload is EthereumScript {
  address internal constant STK_ABPT_V2_IMPL = address(0);

  function _deploy(address stkAbptV2Impl) public returns (address) {
    return address(new ProposalPayload(stkAbptV2Impl));
  }

  function run() external broadcast {
    require(STK_ABPT_V2_IMPL != address(0));
    _deploy(STK_ABPT_V2_IMPL);
  }
}
