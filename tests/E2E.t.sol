// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {GovHelpers} from 'aave-helpers/GovHelpers.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {AaveV3Ethereum, AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {AggregatedStakedTokenV3} from 'aave-stk-v1-5/interfaces/AggregatedStakedTokenV3.sol';
import {IERC20} from 'aave-stk-v1-5/interfaces/IERC20.sol';
import {DeployOracles} from '../scripts/00_PriceOracles.s.sol';
import {DeployImpl} from '../scripts/01_DeployStkAbptV2Impl.sol';
import {DeployPayload} from '../scripts/02_DeployPayload.sol';
import {StkABPTMigrator} from '../src/contracts/StkABPTMigrator.sol';
import {SigUtils} from './SigUtils.sol';
import {BalancerSharedPoolPriceProvider, BPool} from '../src/contracts/lp-oracle-contracts/aggregators/BalancerSharedPoolPriceProvider.sol';
import {BalancerV2SharedPoolPriceProvider, BVaultV2, BPoolV2} from '../src/contracts/lp-oracle-contracts/aggregators/BalancerV2SharedPoolPriceProvider.sol';
import {Addresses} from '../src/libs/Addresses.sol';

contract E2E is Test {
  address constant STK_ABPT_WHALE = 0xF23c8539069C471F5C12692a3471C9F4E8B88BC2;
  address public constant STK_ABPT_V1 = 0xa1116930326D21fB917d5A27F1E9943A9595fb47;

  address public stkAbptV1Impl;
  address public stkAbptV2Impl;
  address public stkABPTV2;
  StkABPTMigrator public migrator;
  BalancerSharedPoolPriceProvider abptOracle;
  BalancerV2SharedPoolPriceProvider abptv2Oracle;

  uint256 internal ownerPrivateKey;
  address internal owner;

  function setUp() external {
    vm.createSelectFork(vm.rpcUrl('mainnet'), 17663919);
    DeployOracles step0 = new DeployOracles();
    (address oracle1, address oracle2) = step0._deploy();
    abptOracle = BalancerSharedPoolPriceProvider(oracle1);
    abptv2Oracle = BalancerV2SharedPoolPriceProvider(oracle2);

    // deploy impls
    DeployImpl step1 = new DeployImpl();
    (stkAbptV1Impl, stkAbptV2Impl, stkABPTV2) = step1._deploy();

    // deploy actual payload
    DeployPayload step2 = new DeployPayload();
    address payload = step2._deploy(stkAbptV1Impl, stkAbptV2Impl, stkABPTV2);

    // deploy migration helper
    migrator = new StkABPTMigrator(stkABPTV2);

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
    uint256 amount = IERC20(STK_ABPT_V1).balanceOf(owner);
    IERC20(STK_ABPT_V1).approve(address(migrator), type(uint256).max);
    uint[] memory tokenOutAmountsMin = new uint[](2);

    // this should happen offchain
    uint256 minBptOut = (((amount * uint256(abptOracle.latestAnswer())) /
      uint256(abptv2Oracle.latestAnswer())) * 995) / 1000;

    migrator.migrateStkABPT(amount, tokenOutAmountsMin, minBptOut, true);
    assertEq(IERC20(stkABPTV2).balanceOf(owner), 232053426840979065985899);
  }

  /**
   * @dev Migrate partial stkAbpt -> stkAbpt v2 via BActions
   */
  function testMigratePartialStkAbpt() public {
    IERC20(STK_ABPT_V1).approve(address(migrator), type(uint256).max);
    uint[] memory tokenOutAmountsMin = new uint[](2);
    migrator.migrateStkABPT(IERC20(STK_ABPT_V1).balanceOf(owner), tokenOutAmountsMin, 0, false);
    assertEq(IERC20(stkABPTV2).balanceOf(owner), 231282239606672010155655);
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

  function testClaimRewards() public {
    testMigrateStkAbpt();
    vm.warp(block.timestamp + 10000);
    uint256 rewards = AggregatedStakedTokenV3(stkABPTV2).getTotalRewardsBalance(owner);
    assertGt(rewards, 0);
    AggregatedStakedTokenV3(stkABPTV2).claimRewards(owner, type(uint256).max);
  }
}

contract OracleTest is Test {
  function setUp() external {
    vm.createSelectFork(vm.rpcUrl('mainnet'), 17663919);
  }

  function testV1OraclePrice() public {
    uint256[][] memory approxMatrix = new uint256[][](0);
    uint8[] memory decimals = new uint8[](2);
    decimals[0] = 18;
    decimals[1] = 18;
    BalancerSharedPoolPriceProvider oracle = new BalancerSharedPoolPriceProvider({
      _pool: BPool(Addresses.ABPT_V1_BPOOL),
      _decimals: decimals,
      _priceOracle: AaveV3Ethereum.ORACLE,
      _maxPriceDeviation: 50000000000000000,
      _K: 2000000000000000000,
      _powerPrecision: 100000000,
      _approximationMatrix: approxMatrix
    });

    console.log(uint256(oracle.latestAnswer()));
  }

  function testV2OraclePrice() public {
    uint256[][] memory approxMatrix = new uint256[][](0);
    uint8[] memory decimals = new uint8[](2);
    decimals[0] = 18;
    decimals[1] = 18;
    BalancerV2SharedPoolPriceProvider oracle = new BalancerV2SharedPoolPriceProvider({
      _pool: BPoolV2(Addresses.ABPT_V2),
      _vault: BVaultV2(Addresses.BALANCER_VAULT),
      _decimals: decimals,
      _priceOracle: AaveV3Ethereum.ORACLE,
      _maxPriceDeviation: 50000000000000000,
      _K: 2000000000000000000,
      _powerPrecision: 100000000,
      _approximationMatrix: approxMatrix
    });

    console.log(uint256(oracle.latestAnswer()));
  }
}
