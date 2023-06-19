// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {EthereumScript} from 'aave-helpers/ScriptUtils.sol';
import {IWeightedPool2TokensFactory} from '../src/interfaces/IWeightedPool2TokensFactory.sol';
import {IWeightedPool2Tokens} from '../src/interfaces/IWeightedPool2Tokens.sol';
import {IERC20} from 'aave-stk-v1-5/interfaces/IERC20.sol';

/**
 * @notice Deploys a balancer weighted pool with AAVE/wstETH 80/20 composition.
 */
contract DeployPool is EthereumScript {
  IWeightedPool2TokensFactory internal constant BALANCER_WEIGHTED_POOL_FACTORY =
    IWeightedPool2TokensFactory(0xA5bf2ddF098bb0Ef6d120C98217dD6B141c74EE0);

  function _deploy() internal returns (address, bytes32) {
    IERC20[] memory assets = new IERC20[](2);
    assets[0] = IERC20(AaveV3EthereumAssets.AAVE_UNDERLYING);
    assets[1] = IERC20(AaveV3EthereumAssets.wstETH_UNDERLYING);
    uint256[] memory weights = new uint256[](2);
    weights[0] = 0.8 ether;
    weights[1] = 0.2 ether;

    address pool = BALANCER_WEIGHTED_POOL_FACTORY.create(
      'Aave Balancer Pool Token V2', // name
      'ABPT V2', // symbol
      assets,
      weights,
      0.001 ether, // fee
      false, // oracleEnabled?
      AaveGovernanceV2.SHORT_EXECUTOR
    );
    return (pool, IWeightedPool2Tokens(pool).getPoolId());
  }

  function run() external broadcast {
    _deploy();
  }
}
