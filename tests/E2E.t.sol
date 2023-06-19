// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {GovHelpers} from 'aave-helpers/GovHelpers.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {DeployPool} from '../scripts/01_DeployPool.s.sol';
import {DeployImpl} from '../scripts/02_DeployStkAbptV2Impl.sol';
import {DeployPayload} from '../scripts/03_DeployPayload.sol';

contract E2E is Test {
  function setUp() external {
    vm.createSelectFork(vm.rpcUrl('mainnet'), 17514427);
  }

  function testE2E() public {
    DeployPool step1 = new DeployPool();
    (address pool, bytes32 poolId) = step1._deploy();
    DeployImpl step2 = new DeployImpl();
    address stkAbptV2Impl = step2._deploy(pool);
    DeployPayload step3 = new DeployPayload();
    address payload = step3._deploy(stkAbptV2Impl);

    GovHelpers.executePayload(vm, payload, AaveGovernanceV2.SHORT_EXECUTOR);
  }
}
