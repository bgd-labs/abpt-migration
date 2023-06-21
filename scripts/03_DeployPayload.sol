// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {EthereumScript} from 'aave-helpers/ScriptUtils.sol';
import {ProposalPayload} from '../src/contracts/ProposalPayload.sol';

/**
 * @notice Deploys a the proposalPayload
 */
contract DeployPayload is EthereumScript {
  address internal constant STK_ABPT_V1_IMPL = address(0);
  address internal constant STK_ABPT_V2_IMPL = address(0);

  function _deploy(
    address stkAbptV1Impl,
    address stkAbptV2Impl,
    address stkAbptV2Proxy,
    address poolV2,
    bytes32 poolV2Id
  ) public returns (address) {
    require(stkAbptV1Impl != address(0));
    require(stkAbptV2Impl != address(0));
    require(stkAbptV2Proxy != address(0));
    require(poolV2 != address(0));
    require(poolV2Id != bytes32(0));
    return
      address(new ProposalPayload(stkAbptV1Impl, stkAbptV2Impl, stkAbptV2Proxy, poolV2, poolV2Id));
  }

  function run() external broadcast {
    _deploy(STK_ABPT_V1_IMPL, STK_ABPT_V2_IMPL, address(0), address(0), bytes32(0));
  }
}
