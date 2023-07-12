// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV3Ethereum} from 'aave-address-book/AaveV3Ethereum.sol';
import {EthereumScript} from 'aave-helpers/ScriptUtils.sol';
import {BalancerSharedPoolPriceProvider, BPool} from '../src/contracts/lp-oracle-contracts/aggregators/BalancerSharedPoolPriceProvider.sol';
import {BalancerV2SharedPoolPriceProvider, BVaultV2, BPoolV2} from '../src/contracts/lp-oracle-contracts/aggregators/BalancerV2SharedPoolPriceProvider.sol';
import {Addresses} from '../src/libs/Addresses.sol';

contract DeployOracles is EthereumScript {
  function _deploy() public returns (address, address) {
    uint256[][] memory approxMatrix = new uint256[][](0);
    uint8[] memory decimals = new uint8[](2);
    decimals[0] = 18;
    decimals[1] = 18;

    BalancerSharedPoolPriceProvider v1oracle = new BalancerSharedPoolPriceProvider({
      _pool: BPool(Addresses.ABPT_V1_BPOOL),
      _decimals: decimals,
      _priceOracle: AaveV3Ethereum.ORACLE,
      _maxPriceDeviation: 50000000000000000,
      _K: 2000000000000000000,
      _powerPrecision: 100000000,
      _approximationMatrix: approxMatrix
    });

    BalancerV2SharedPoolPriceProvider v2oracle = new BalancerV2SharedPoolPriceProvider({
      _pool: BPoolV2(Addresses.ABPT_V2),
      _vault: BVaultV2(Addresses.BALANCER_VAULT),
      _decimals: decimals,
      _priceOracle: AaveV3Ethereum.ORACLE,
      _maxPriceDeviation: 50000000000000000,
      _K: 2000000000000000000,
      _powerPrecision: 100000000,
      _approximationMatrix: approxMatrix
    });
    return (address(v1oracle), address(v2oracle));
  }

  function run() external broadcast {
    _deploy();
  }
}
