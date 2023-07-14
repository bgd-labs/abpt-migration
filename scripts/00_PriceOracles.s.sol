// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV2Ethereum} from 'aave-address-book/AaveV2Ethereum.sol';
import {AaveV3Ethereum, IAaveOracle} from 'aave-address-book/AaveV3Ethereum.sol';
import {EthereumScript} from 'aave-helpers/ScriptUtils.sol';
import {BalancerSharedPoolPriceProvider, BPool} from '../src/contracts/BalancerSharedPoolPriceProvider.sol';
import {BalancerV2SharedPoolPriceProvider, BVaultV2, BPoolV2} from '../src/contracts/BalancerV2SharedPoolPriceProvider.sol';
import {Addresses} from '../src/libs/Addresses.sol';

contract DeployOracles is EthereumScript {
  function getMatrixValuesV2() internal returns (uint256[][] memory, uint256) {
    string[] memory inputs = new string[](2);
    inputs[0] = 'node';
    inputs[1] = 'scripts/generateMatrixv2.js';
    bytes memory matrix = vm.ffi(inputs);
    return abi.decode(matrix, (uint256[][], uint256));
  }

  function getMatrixValuesV1() internal returns (uint256[][] memory, uint256) {
    string[] memory inputs = new string[](2);
    inputs[0] = 'node';
    inputs[1] = 'scripts/generateMatrix.js';
    bytes memory matrix = vm.ffi(inputs);
    return abi.decode(matrix, (uint256[][], uint256));
  }

  function _deploy() public returns (address, address) {
    (uint256[][] memory approxMatrixV1, uint256 KV1) = getMatrixValuesV1();
    uint256[] memory weights = new uint256[](2);
    weights[0] = 200000000000000000;
    weights[1] = 800000000000000000;
    uint8[] memory decimals = new uint8[](2);
    decimals[0] = 18;
    decimals[1] = 18;
    uint256 maxPriceDeviation = 0.05 ether;
    uint256 powerPrecision = 0.1 gwei;

    BalancerSharedPoolPriceProvider v1oracle = new BalancerSharedPoolPriceProvider({
      _pool: BPool(Addresses.ABPT_V1_BPOOL),
      _decimals: decimals,
      _priceOracle: AaveV3Ethereum.ORACLE, // IAaveOracle(address(AaveV2Ethereum.ORACLE)),
      _maxPriceDeviation: maxPriceDeviation,
      _K: KV1,
      _powerPrecision: powerPrecision,
      _approximationMatrix: approxMatrixV1
    });

    (uint256[][] memory approxMatrixV2, uint256 KV2) = getMatrixValuesV2();

    BalancerV2SharedPoolPriceProvider v2oracle = new BalancerV2SharedPoolPriceProvider({
      _pool: BPoolV2(Addresses.ABPT_V2),
      _vault: BVaultV2(Addresses.BALANCER_VAULT),
      _decimals: decimals,
      _priceOracle: AaveV3Ethereum.ORACLE,
      _maxPriceDeviation: maxPriceDeviation,
      _K: KV2,
      _powerPrecision: powerPrecision,
      _approximationMatrix: approxMatrixV2
    });
    return (address(v1oracle), address(v2oracle));
  }

  function run() external broadcast {
    _deploy();
  }
}
