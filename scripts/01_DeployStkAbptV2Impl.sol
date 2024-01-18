// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MiscEthereum} from 'aave-address-book/MiscEthereum.sol';
import {AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {EthereumScript} from 'aave-helpers/ScriptUtils.sol';
import {StakedTokenV3 as StakedTokenV3NoCooldown, IERC20 as IERC20NoCooldown} from 'stk-no-cooldown/contracts/StakedTokenV3.sol';
import {StakeToken} from 'stake-token/contracts/StakeToken.sol';
import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {ITransparentProxyFactory} from 'solidity-utils/contracts/transparent-proxy/interfaces/ITransparentProxyFactory.sol';
import {IWeightedPool} from '../src/interfaces/IWeightedPool.sol';
import {GenericProposal} from '../src/libs/GenericProposal.sol';
import {Addresses} from '../src/libs/Addresses.sol';

/**
 * @notice Deploys a the implementation for the pool with the bricked initialize.
 */
contract DeployImpl is EthereumScript {
  function _deploy() public returns (address, address) {
    address stkABPTV2Impl = address(
      new StakeToken(
        'stk AAVE/wstETH BPTv2',
        IERC20(Addresses.ABPT_V2),
        IERC20(AaveV3EthereumAssets.AAVE_UNDERLYING),
        GenericProposal.UNSTAKE_WINDOW,
        GenericProposal.REWARDS_VAULT,
        GenericProposal.EMISSION_MANAGER
      )
    );

    address tokenProxy = ITransparentProxyFactory(MiscEthereum.TRANSPARENT_PROXY_FACTORY).create(
      address(stkABPTV2Impl),
      MiscEthereum.PROXY_ADMIN,
      abi.encodeWithSelector(
        StakeToken.initialize.selector,
        'stk AAVE/wstETH BPTv2', // name
        'stkAAVEwstETHBPTv2', // symbol
        GenericProposal.SLASHING_ADMIN,
        GenericProposal.COOLDOWN_ADMIN,
        GenericProposal.CLAIM_HELPER,
        GenericProposal.MAX_SLASHING,
        GenericProposal.COOLDOWN_SECONDS
      )
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
      tokenProxy
    );
  }

  function run() external broadcast {
    _deploy();
  }
}
