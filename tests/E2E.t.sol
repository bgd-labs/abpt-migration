// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {GovHelpers} from 'aave-helpers/GovHelpers.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {AaveV3Ethereum, AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {AggregatedStakedTokenV3} from 'aave-stk-v1-5/interfaces/AggregatedStakedTokenV3.sol';
import {IERC20} from 'aave-stk-v1-5/interfaces/IERC20.sol';
import {DeployPool} from '../scripts/01_DeployPool.s.sol';
import {DeployImpl} from '../scripts/02_DeployStkAbptV2Impl.sol';
import {DeployPayload} from '../scripts/03_DeployPayload.sol';
import {StkABPTMigrator} from '../src/contracts/StkABPTMigrator.sol';
import {SigUtils} from './SigUtils.sol';

contract E2E is Test {
  address constant STK_ABPT_WHALE = 0xF23c8539069C471F5C12692a3471C9F4E8B88BC2;
  address public constant STK_ABPT_V1 = 0xa1116930326D21fB917d5A27F1E9943A9595fb47;

  address public stkAbptV1Impl;
  address public stkAbptV2Impl;
  address public stkABPTV2;
  address public v2Pool;
  bytes32 public v2PoolId;
  StkABPTMigrator public migrator;

  uint256 internal ownerPrivateKey;
  address internal owner;

  function setUp() external {
    vm.createSelectFork(vm.rpcUrl('mainnet'), 17514427);
    // Deploy pool TODO: remove once pool is live
    DeployPool step1 = new DeployPool();
    (v2Pool, v2PoolId) = step1._deploy();
    step1._init(v2PoolId);

    // deploy impls
    DeployImpl step2 = new DeployImpl();
    (stkAbptV1Impl, stkAbptV2Impl, stkABPTV2) = step2._deploy(v2Pool);

    // deploy actual payload
    DeployPayload step3 = new DeployPayload();
    address payload = step3._deploy(stkAbptV1Impl, stkAbptV2Impl, stkABPTV2, v2Pool, v2PoolId);

    // deploy migration helper
    migrator = new StkABPTMigrator(v2Pool, stkABPTV2);

    // execute proposal
    GovHelpers.executePayload(vm, payload, AaveGovernanceV2.SHORT_EXECUTOR);

    // create test user
    ownerPrivateKey = 0xA11CE;
    owner = vm.addr(ownerPrivateKey);

    // transfer funds to test user
    vm.startPrank(STK_ABPT_WHALE);
    AggregatedStakedTokenV3(STK_ABPT_V1).transfer(
      owner,
      AggregatedStakedTokenV3(STK_ABPT_V1).balanceOf(STK_ABPT_WHALE)
    );
    vm.stopPrank();
    vm.startPrank(owner);
  }

  /**
   * @dev The proposal upgrades the implementation of stkABPT.
   * The new version enters post slashing mode, which means ppl should be able to withdraw without a cooldown.
   */
  function testRedeem() public {
    address abpt = AggregatedStakedTokenV3(STK_ABPT_V1).STAKED_TOKEN();
    uint256 stkAbptBalanceBefore = IERC20(STK_ABPT_V1).balanceOf(owner);
    uint256 abptBalanceBefore = IERC20(abpt).balanceOf(owner);
    AggregatedStakedTokenV3(STK_ABPT_V1).redeem(owner, stkAbptBalanceBefore);

    assertEq(IERC20(STK_ABPT_V1).balanceOf(owner), 0);
    assertEq(IERC20(abpt).balanceOf(owner), abptBalanceBefore + stkAbptBalanceBefore);
  }

  /**
   * @dev Migrate stkAbpt -> stkAbpt v2 via BActions
   */
  function testMigrateStkAbpt() public {
    IERC20(STK_ABPT_V1).approve(address(migrator), type(uint256).max);
    uint[] memory tokenOutAmountsMin = new uint[](2);
    migrator.migrateStkABPT(IERC20(STK_ABPT_V1).balanceOf(owner), tokenOutAmountsMin, 0, true);
    assertEq(IERC20(stkABPTV2).balanceOf(owner), 231860133214691104707063);
  }

  /**
   * @dev Migrate partial stkAbpt -> stkAbpt v2 via BActions
   */
  function testMigratePartialStkAbpt() public {
    IERC20(STK_ABPT_V1).approve(address(migrator), type(uint256).max);
    uint[] memory tokenOutAmountsMin = new uint[](2);
    migrator.migrateStkABPT(IERC20(STK_ABPT_V1).balanceOf(owner), tokenOutAmountsMin, 0, false);
    assertEq(IERC20(stkABPTV2).balanceOf(owner), 14895707098461386766742);
  }

  function testMigrationWithPermit() public {
    SigUtils.Permit memory permit = SigUtils.Permit({
      owner: owner,
      spender: address(migrator),
      value: IERC20(STK_ABPT_V1).balanceOf(owner),
      nonce: AggregatedStakedTokenV3(STK_ABPT_V1)._nonces(owner),
      deadline: block.timestamp + 1 days
    });

    bytes32 digest = SigUtils.getTypedDataHash(
      permit,
      0x97be788f2bcc1c4e15c03b6cfa54541dad55d4d1343f8cfcb92088c1c105de17
    );

    (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);
    uint[] memory tokenOutAmountsMin = new uint[](2);
    migrator.migrateStkABPTWithPermit(
      permit.owner,
      permit.value,
      permit.deadline,
      v,
      r,
      s,
      tokenOutAmountsMin,
      0,
      true
    );
  }
}
