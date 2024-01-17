// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {MiscEthereum} from 'aave-address-book/MiscEthereum.sol';
import {ProxyAdmin} from 'solidity-utils/contracts/transparent-proxy/ProxyAdmin.sol';
import {TransparentUpgradeableProxy} from 'solidity-utils/contracts/transparent-proxy/TransparentUpgradeableProxy.sol';
import {GenericProposal} from '../libs/GenericProposal.sol';
import {DistributionTypes} from 'stake-token/contracts/lib/DistributionTypes.sol';
import {IAaveDistributionManager} from 'stake-token/contracts/IAaveDistributionManager.sol';
import {IAggregatedStakeToken} from 'stake-token/contracts/IAggregatedStakeToken.sol';
import {AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {AaveSafetyModule} from 'aave-address-book/AaveSafetyModule.sol';

/**
 * @title StkABPTV2 Proposal
 * @author BGD Labs
 * @notice migrates emissions to a new stkABPT
 */
contract ProposalPayload {
  uint256 public constant EMISSION_PER_SECOND = 4456018518518518; // same as current

  address public immutable STK_ABPT_V1_IMPL;
  address public immutable STK_ABPT_V2_PROXY;

  constructor(address newStkABPTV1Impl, address stkABPTV2Proxy) {
    STK_ABPT_V1_IMPL = newStkABPTV1Impl;
    STK_ABPT_V2_PROXY = stkABPTV2Proxy;
  }

  function execute() external {
    // 1. disable cooldown by upgrading the impl
    ProxyAdmin(MiscEthereum.PROXY_ADMIN).upgradeAndCall(
      TransparentUpgradeableProxy(payable(AaveSafetyModule.STK_ABPT)),
      STK_ABPT_V1_IMPL,
      abi.encodeWithSignature('initialize()')
    );

    // 2. stop emission on module v1
    DistributionTypes.AssetConfigInput[]
      memory disableConfigs = new DistributionTypes.AssetConfigInput[](1);
    disableConfigs[0] = DistributionTypes.AssetConfigInput({
      emissionPerSecond: 0,
      totalStaked: 0, // it's overwritten internally
      underlyingAsset: AaveSafetyModule.STK_ABPT
    });
    IAaveDistributionManager(AaveSafetyModule.STK_ABPT).configureAssets(disableConfigs);
    MiscEthereum.AAVE_ECOSYSTEM_RESERVE_CONTROLLER.approve(
      MiscEthereum.ECOSYSTEM_RESERVE,
      AaveV3EthereumAssets.AAVE_UNDERLYING,
      AaveSafetyModule.STK_ABPT,
      0
    );
    MiscEthereum.AAVE_ECOSYSTEM_RESERVE_CONTROLLER.approve(
      MiscEthereum.ECOSYSTEM_RESERVE,
      AaveV3EthereumAssets.AAVE_UNDERLYING,
      AaveSafetyModule.STK_ABPT,
      15_000 ether // rough estimation on total claimable + emission until execution
    );

    // 3. start emission on module v2
    IAggregatedStakeToken(STK_ABPT_V2_PROXY).setDistributionEnd(
      block.timestamp + GenericProposal.DISTRIBUTION_DURATION
    );
    DistributionTypes.AssetConfigInput[]
      memory enableConfigs = new DistributionTypes.AssetConfigInput[](1);
    enableConfigs[0] = DistributionTypes.AssetConfigInput({
      emissionPerSecond: uint128(EMISSION_PER_SECOND),
      totalStaked: 0, // it's overwritten internally
      underlyingAsset: STK_ABPT_V2_PROXY
    });
    IAaveDistributionManager(STK_ABPT_V2_PROXY).configureAssets(enableConfigs);
    MiscEthereum.AAVE_ECOSYSTEM_RESERVE_CONTROLLER.approve(
      MiscEthereum.ECOSYSTEM_RESERVE,
      AaveV3EthereumAssets.AAVE_UNDERLYING,
      STK_ABPT_V2_PROXY,
      EMISSION_PER_SECOND * GenericProposal.DISTRIBUTION_DURATION
    );
  }
}
