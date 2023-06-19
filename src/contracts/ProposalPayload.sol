// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {AaveV3Ethereum, AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {AaveMisc} from 'aave-address-book/AaveMisc.sol';
import {ITransparentProxyFactory} from 'solidity-utils/contracts/transparent-proxy/interfaces/ITransparentProxyFactory.sol';
import {GenericProposal} from '../libs/GenericProposal.sol';
import {DistributionTypes} from 'aave-stk-v1-5/lib/DistributionTypes.sol';
import {IAaveDistributionManager} from 'aave-stk-v1-5/interfaces/IAaveDistributionManager.sol';

contract ProposalPayload {
  address public constant STK_ABPT_V1 = 0xa1116930326D21fB917d5A27F1E9943A9595fb47;
  address public immutable STK_ABPT_V2_IMPL;

  constructor(address newStkABPTImpl) {
    STK_ABPT_V2_IMPL = newStkABPTImpl;
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

    // 2. disable cooldown
    // TODO: either set cooldown to 0, or upgrade impl

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
