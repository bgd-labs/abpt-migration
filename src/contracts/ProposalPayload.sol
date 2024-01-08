// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {AaveMisc} from 'aave-address-book/AaveMisc.sol';
import {ProxyAdmin} from 'solidity-utils/contracts/transparent-proxy/ProxyAdmin.sol';
import {TransparentUpgradeableProxy} from 'solidity-utils/contracts/transparent-proxy/TransparentUpgradeableProxy.sol';
import {GenericProposal} from '../libs/GenericProposal.sol';
import {DistributionTypes} from 'stake-token/contracts/lib/DistributionTypes.sol';
import {IAaveDistributionManager} from 'stake-token/contracts/IAaveDistributionManager.sol';
import {Vault} from '../interfaces/Actions.sol';
import {Addresses} from '../libs/Addresses.sol';

/**
 * @title StkABPTV2 Proposal
 * @author BGD Labs
 * @notice migrates emissions to a new stkABPT
 */
contract ProposalPayload {
  address public constant AAVE = Addresses.AAVE;
  address public constant WSTETH = Addresses.WSTETH;
  address public constant STK_ABPT_V1 = Addresses.STK_ABPT_V1;
  Vault public constant VAULT = Vault(Addresses.BALANCER_VAULT);

  address public immutable STK_ABPT_V1_IMPL;
  address public immutable STK_ABPT_V2_IMPL;
  address public immutable STK_ABPT_V2_PROXY;

  constructor(address newStkABPTV1Impl, address newStkABPTV2Impl, address stkABPTV2Proxy) {
    STK_ABPT_V1_IMPL = newStkABPTV1Impl;
    STK_ABPT_V2_IMPL = newStkABPTV2Impl;
    STK_ABPT_V2_PROXY = stkABPTV2Proxy;
  }

  function execute() external {
    // 1. stop emission on module v1
    DistributionTypes.AssetConfigInput[]
      memory disableConfigs = new DistributionTypes.AssetConfigInput[](1);
    disableConfigs[0] = DistributionTypes.AssetConfigInput({
      emissionPerSecond: 0,
      totalStaked: 0, // it's overwritten internally
      underlyingAsset: STK_ABPT_V1
    });
    IAaveDistributionManager(STK_ABPT_V1).configureAssets(disableConfigs);

    // 2. disable cooldown by upgrading the impl
    ProxyAdmin(AaveMisc.PROXY_ADMIN_ETHEREUM).upgradeAndCall(
      TransparentUpgradeableProxy(payable(STK_ABPT_V1)),
      STK_ABPT_V1_IMPL,
      abi.encodeWithSignature('initialize()')
    );

    // 3. create new SM
    ProxyAdmin(AaveMisc.PROXY_ADMIN_ETHEREUM).upgradeAndCall(
      TransparentUpgradeableProxy(payable(STK_ABPT_V2_PROXY)),
      STK_ABPT_V2_IMPL,
      abi.encodeWithSignature(
        'initialize(address,address,address,uint256,uint256)',
        GenericProposal.SLASHING_ADMIN,
        GenericProposal.COOLDOWN_ADMIN,
        GenericProposal.CLAIM_HELPER,
        GenericProposal.MAX_SLASHING,
        GenericProposal.COOLDOWN_SECONDS
      )
    );

    // 4. start emission on module v2
    AaveMisc.AAVE_ECOSYSTEM_RESERVE_CONTROLLER.approve(
      AaveMisc.ECOSYSTEM_RESERVE,
      AAVE,
      STK_ABPT_V2_PROXY,
      180_000 ether // TODO: what is the correct value here?
    );
    DistributionTypes.AssetConfigInput[]
      memory enableConfigs = new DistributionTypes.AssetConfigInput[](1);
    enableConfigs[0] = DistributionTypes.AssetConfigInput({
      emissionPerSecond: 6365740740740741, // same as current
      totalStaked: 0, // it's overwritten internally
      underlyingAsset: STK_ABPT_V2_PROXY
    });
    IAaveDistributionManager(STK_ABPT_V2_PROXY).configureAssets(enableConfigs);
  }
}
