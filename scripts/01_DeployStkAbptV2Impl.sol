// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveMisc} from 'aave-address-book/AaveMisc.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {EthereumScript} from 'aave-helpers/ScriptUtils.sol';
import {StakedTokenV3 as StakedTokenV3NoCooldown, IERC20 as IERC20NoCooldown} from 'stk-no-cooldown/contracts/StakedTokenV3.sol';
import {StakedTokenV3} from 'aave-stk-v1-5/contracts/StakedTokenV3.sol';
import {IERC20} from 'aave-stk-v1-5/interfaces/IERC20.sol';
import {ITransparentProxyFactory} from 'solidity-utils/contracts/transparent-proxy/interfaces/ITransparentProxyFactory.sol';
import {IWeightedPool} from '../src/interfaces/IWeightedPool.sol';
import {GenericProposal} from '../src/libs/GenericProposal.sol';
import {Addresses} from '../src/libs/Addresses.sol';

/**
 * This is an completely empty contract.
 * It just exists to initialize Proxies with "some implementation"
 */
contract PlaceholderContract {

}

/**
 * @notice Deploys a the implementation for the pool with the bricked initialize.
 */
contract DeployImpl is EthereumScript {
  function _deploy() public returns (address, address, address) {
    address stkABPTV2Impl = address(
      new StakedTokenV3(
        IERC20(Addresses.ABPT_V2),
        IERC20(AaveV3EthereumAssets.AAVE_UNDERLYING),
        GenericProposal.UNSTAKE_WINDOW,
        GenericProposal.REWARDS_VAULT,
        GenericProposal.EMISSION_MANAGER,
        GenericProposal.DISTRIBUTION_DURATION
      )
    );

    address tokenProxy = ITransparentProxyFactory(AaveMisc.TRANSPARENT_PROXY_FACTORY_ETHEREUM)
      .createDeterministic(
        address(new PlaceholderContract()),
        AaveMisc.PROXY_ADMIN_ETHEREUM,
        bytes(''),
        'ABPT_V2'
      );

    return (
      address(
        new StakedTokenV3NoCooldown(
          IERC20NoCooldown(Addresses.ABPT_V1),
          IERC20NoCooldown(AaveV3EthereumAssets.AAVE_UNDERLYING),
          GenericProposal.UNSTAKE_WINDOW,
          GenericProposal.REWARDS_VAULT,
          GenericProposal.EMISSION_MANAGER,
          GenericProposal.DISTRIBUTION_DURATION
        )
      ),
      stkABPTV2Impl,
      tokenProxy
    );
  }

  function run() external broadcast {
    _deploy();
  }
}
