// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {EthereumScript} from 'aave-helpers/ScriptUtils.sol';
import {IWeightedPool2TokensFactory} from '../src/interfaces/IWeightedPool2TokensFactory.sol';
import {IWeightedPool2Tokens} from '../src/interfaces/IWeightedPool2Tokens.sol';

contract DeployPool is EthereumScript {
  IWeightedPool2TokensFactory constant BALANCER_WEIGHTED_POOL_FACTORY =
    IWeightedPool2TokensFactory(0xA5bf2ddF098bb0Ef6d120C98217dD6B141c74EE0);

  function run() external broadcast {
    IERC20[] memory assets = new IERC20[](2);
    assets[0] = AaveV3EthereumAssets.AAVE_UNDERLYING;
    assets[1] = AaveV3EthereumAssets.wstETH_UNDERLYING;
    uint256[] memory weights = new uint256[](2);
    weights[0] = 0.8 ether;
    weights[1] = 0.2 ether;

    address pool = BALANCER_WEIGHTED_POOL_FACTORY.create(
      'Aave balancer pool v2',
      'abptv2',
      assets,
      weights,
      0.001 ether,
      false, // oracleEnabled?
      GovHelpers.SHORT_EXECUTOR
    );

    emit log_address(pool);
    emit log_bytes32(IWeightedPool2Tokens(pool).getPoolId());
  }
}
