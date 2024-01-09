// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {GovV3Helpers} from 'aave-helpers/GovV3Helpers.sol';
import {AaveV3Ethereum, AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {IAggregatedStakeToken} from 'stake-token/contracts/IAggregatedStakeToken.sol';
import {AggregatedStakedTokenV3} from 'stk-no-cooldown/interfaces/AggregatedStakedTokenV3.sol';
import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {DeployOracles} from '../scripts/00_PriceOracles.s.sol';
import {DeployImpl} from '../scripts/01_DeployStkAbptV2Impl.sol';
import {DeployPayload} from '../scripts/02_DeployPayload.sol';
import {StkABPTMigrator} from '../src/contracts/StkABPTMigrator.sol';
import {SigUtils} from './SigUtils.sol';
import {BalancerSharedPoolPriceProvider, BPool} from '../src/contracts/BalancerSharedPoolPriceProvider.sol';
import {BalancerV2SharedPoolPriceProvider, BVaultV2, BPoolV2} from '../src/contracts/BalancerV2SharedPoolPriceProvider.sol';
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
    /**
     * ETH: ~2006 $
     * AAVE: ~80.42 $
     */
    vm.createSelectFork(vm.rpcUrl('mainnet'), 18961127);
    // DeployOracles step0 = new DeployOracles();
    // (address oracle1, address oracle2) = step0._deploy();
    abptOracle = BalancerSharedPoolPriceProvider(0x209Ad99bd808221293d03827B86cC544bcA0023b);
    abptv2Oracle = BalancerV2SharedPoolPriceProvider(0xADf86b537eF08591c2777E144322E8b0Ca7E82a7);

    // deploy impls
    DeployImpl step1 = new DeployImpl();
    (stkAbptV1Impl, stkAbptV2Impl, stkABPTV2) = step1._deploy();

    // deploy actual payload
    DeployPayload step2 = new DeployPayload();
    address payload = step2._deploy(stkAbptV1Impl, stkAbptV2Impl, stkABPTV2);

    // deploy migration helper
    migrator = new StkABPTMigrator(stkABPTV2);

    // execute proposal
    GovV3Helpers.executePayload(vm, payload);

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
  function test_redeem() public {
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
  function test_migrateStkAbpt() public {
    uint256 amount = IERC20(STK_ABPT_V1).balanceOf(owner);
    IERC20(STK_ABPT_V1).approve(address(migrator), type(uint256).max);
    uint[] memory tokenOutAmountsMin = new uint[](2);

    // calculate minOut based on $ value - 0.01 %
    // this should happen offchain
    uint256 minBptOut = ((amount * uint256(abptOracle.latestAnswer())) /
      uint256(abptv2Oracle.latestAnswer()));
    uint256 minBptOutWithSlippage = (minBptOut * 9_999) / 10_000;

    migrator.migrateStkABPT(amount, tokenOutAmountsMin, minBptOutWithSlippage, true);

    uint256 actualBPT = IERC20(stkABPTV2).balanceOf(owner);
    assertGe(actualBPT, minBptOutWithSlippage);
    assertLt(actualBPT - minBptOutWithSlippage, minBptOut - minBptOutWithSlippage);
  }

  /**
   * @dev Migrate partial stkAbpt -> stkAbpt v2 via BActions
   * In this case you would need to control slippage
   */
  function test_migratePartialStkAbpt() public {
    IERC20(STK_ABPT_V1).approve(address(migrator), type(uint256).max);
    uint[] memory tokenOutAmountsMin = new uint[](2);
    migrator.migrateStkABPT(IERC20(STK_ABPT_V1).balanceOf(owner), tokenOutAmountsMin, 0, false);
    uint256 wstETHBalance = IERC20(Addresses.WSTETH).balanceOf(owner);
    uint256 aaveBalance = IERC20(Addresses.AAVE).balanceOf(owner);
    if (wstETHBalance == 0) {
      assertGt(aaveBalance, 0);
    } else {
      assertGt(wstETHBalance, 0);
    }
    assertEq(IERC20(stkABPTV2).balanceOf(owner), 228733940221947756582513);
  }

  function test_migrationWithPermit() public {
    SigUtils.Permit memory permit = SigUtils.Permit({
      owner: owner,
      spender: address(migrator),
      value: AggregatedStakedTokenV3(STK_ABPT_V1).balanceOf(owner),
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

  function test_claimRewards() public {
    test_migrateStkAbpt();
    vm.warp(block.timestamp + 10000);
    uint256 rewards = IAggregatedStakeToken(stkABPTV2).getTotalRewardsBalance(owner);
    assertGt(rewards, 0);
    IAggregatedStakeToken(stkABPTV2).claimRewards(owner, type(uint256).max);
  }
}

contract OracleTest is Test {
  BalancerSharedPoolPriceProvider abptOracle;
  BalancerV2SharedPoolPriceProvider abptv2Oracle;

  function setUp() external {
    vm.createSelectFork(vm.rpcUrl('mainnet'), 17711546);
    DeployOracles step0 = new DeployOracles();
    (address oracle1, address oracle2) = step0._deploy();
    abptOracle = BalancerSharedPoolPriceProvider(oracle1);
    abptv2Oracle = BalancerV2SharedPoolPriceProvider(oracle2);
  }

  function testAAVEPrice() public {
    console.log(AaveV3Ethereum.ORACLE.getAssetPrice(Addresses.AAVE));
  }

  function testV1OraclePrice() public {
    console.log(uint256(abptOracle.latestAnswer()));
  }

  // times out in that block
  function testV2OraclePrice() public {
    console.log(uint256(abptv2Oracle.latestAnswer()));
  }
}
