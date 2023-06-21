// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {AaveV3Ethereum, AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {AaveMisc} from 'aave-address-book/AaveMisc.sol';
import {ITransparentProxyFactory} from 'solidity-utils/contracts/transparent-proxy/interfaces/ITransparentProxyFactory.sol';
import {ProxyAdmin} from 'solidity-utils/contracts/transparent-proxy/ProxyAdmin.sol';
import {TransparentUpgradeableProxy} from 'solidity-utils/contracts/transparent-proxy/TransparentUpgradeableProxy.sol';
import {GenericProposal} from '../libs/GenericProposal.sol';
import {DistributionTypes} from 'aave-stk-v1-5/lib/DistributionTypes.sol';
import {IAaveDistributionManager} from 'aave-stk-v1-5/interfaces/IAaveDistributionManager.sol';
import {Vault} from '../interfaces/Actions.sol';

contract ProposalPayload {
  address public constant AAVE = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;
  address public constant WSTETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
  address public constant STK_ABPT_V1 = 0xa1116930326D21fB917d5A27F1E9943A9595fb47;
  Vault public constant VAULT = Vault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

  address public immutable STK_ABPT_V1_IMPL;
  address public immutable STK_ABPT_V2_IMPL;
  address public immutable BALANCER_POOL_V2;
  bytes32 public immutable BALANCER_POOL_V2_ID;

  constructor(
    address newStkABPTV1Impl,
    address newStkABPTV2Impl,
    address balancerPoolV2,
    bytes32 balancerPoolV2Id
  ) {
    STK_ABPT_V1_IMPL = newStkABPTV1Impl;
    STK_ABPT_V2_IMPL = newStkABPTV2Impl;
    BALANCER_POOL_V2 = balancerPoolV2;
    BALANCER_POOL_V2_ID = balancerPoolV2Id;
  }

  function execute() external {
    // 1. stop emission on module v1
    DistributionTypes.AssetConfigInput[]
      memory disableConfigs = new DistributionTypes.AssetConfigInput[](1);
    disableConfigs[0] = DistributionTypes.AssetConfigInput({
      emissionPerSecond: 0, // same as current
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
    address tokenProxy = ITransparentProxyFactory(AaveMisc.TRANSPARENT_PROXY_FACTORY_ETHEREUM)
      .createDeterministic(
        STK_ABPT_V2_IMPL,
        AaveMisc.PROXY_ADMIN_ETHEREUM,
        abi.encodeWithSignature(
          'initialize(address,address,address,uint256,uint256)',
          GenericProposal.SLASHING_ADMIN,
          GenericProposal.COOLDOWN_ADMIN,
          GenericProposal.CLAIM_HELPER,
          GenericProposal.MAX_SLASHING,
          GenericProposal.COOLDOWN_SECONDS
        ),
        'ABPT_V2'
      );

    // 4. start emission on module v2
    DistributionTypes.AssetConfigInput[]
      memory enableConfigs = new DistributionTypes.AssetConfigInput[](1);
    enableConfigs[0] = DistributionTypes.AssetConfigInput({
      emissionPerSecond: 6365740740740741, // same as current
      totalStaked: 0, // it's overwritten internally
      underlyingAsset: tokenProxy
    });
    IAaveDistributionManager(tokenProxy).configureAssets(enableConfigs);
  }
}
