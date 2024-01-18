// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {EthereumScript} from 'aave-helpers/ScriptUtils.sol';
import {ProposalPayload} from '../src/contracts/ProposalPayload.sol';

/**
 * @notice Deploys a the proposalPayload
 */
contract DeployPayload is EthereumScript {
  address internal constant STK_ABPT_V1_IMPL = address(0);

  function _deploy(address stkAbptV1Impl, address stkAbptV2Proxy) public returns (address) {
    require(stkAbptV1Impl != address(0));
    require(stkAbptV2Proxy != address(0));
    return address(new ProposalPayload(stkAbptV1Impl, stkAbptV2Proxy));
  }

  function run() external broadcast {
    _deploy(STK_ABPT_V1_IMPL, address(0));
  }
}
