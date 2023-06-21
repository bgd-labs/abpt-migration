// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {AaveV3Ethereum, AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {EthereumScript} from 'aave-helpers/ScriptUtils.sol';
import {IWeightedPoolFactory} from '../src/interfaces/IWeightedPoolFactory.sol';
import {IWeightedPool} from '../src/interfaces/IWeightedPool.sol';
import {IRateProvider} from '../src/interfaces/IRateProvider.sol';
import {IERC20} from 'aave-stk-v1-5/interfaces/IERC20.sol';
import {Addresses} from '../src/libs/Addresses.sol';
import {Vault} from '../src/interfaces/Actions.sol';

/**
 * @notice Deploys a balancer weighted pool with AAVE/wstETH 80/20 composition.
 */
contract DeployPool is EthereumScript, Test {
  IWeightedPoolFactory internal constant BALANCER_WEIGHTED_POOL_FACTORY =
    IWeightedPoolFactory(0x897888115Ada5773E02aA29F775430BFB5F34c51);

  function _deploy() public returns (address, bytes32) {
    IERC20[] memory assets = new IERC20[](2);
    assets[0] = IERC20(AaveV3EthereumAssets.wstETH_UNDERLYING);
    assets[1] = IERC20(AaveV3EthereumAssets.AAVE_UNDERLYING);

    uint256[] memory weights = new uint256[](2);
    weights[0] = 0.2 ether;
    weights[1] = 0.8 ether;

    IRateProvider[] memory rateProviders = new IRateProvider[](2);
    // rateProviders[0] = IRateProvider(0x72D07D7DcA67b8A406aD1Ec34ce969c90bFEE768); // not 100% sure if needed or not

    address pool = BALANCER_WEIGHTED_POOL_FACTORY.create(
      'Aave Balancer Pool Token V2', // name
      'ABPT V2', // symbol
      assets,
      weights,
      rateProviders,
      0.001 ether, // fee
      AaveGovernanceV2.SHORT_EXECUTOR,
      'AAVE_SM_AAVE_WSTETH_80_20'
    );
    bytes32 poolId = IWeightedPool(pool).getPoolId();

    return (pool, poolId);
  }

  function _init(bytes32 poolId) public {
    deal(AaveV3EthereumAssets.wstETH_UNDERLYING, address(AaveV3Ethereum.COLLECTOR), 1 ether);
    vm.startPrank(address(AaveV3Ethereum.COLLECTOR));
    address[] memory erc20Assets = new address[](2);
    erc20Assets[0] = AaveV3EthereumAssets.wstETH_UNDERLYING;
    erc20Assets[1] = AaveV3EthereumAssets.AAVE_UNDERLYING;
    uint256[] memory maxAmountsIn = new uint256[](2);
    IERC20(AaveV3EthereumAssets.wstETH_UNDERLYING).approve(
      Addresses.BALANCER_VAULT,
      type(uint256).max
    );
    IERC20(AaveV3EthereumAssets.AAVE_UNDERLYING).approve(
      Addresses.BALANCER_VAULT,
      type(uint256).max
    );
    maxAmountsIn[0] = IERC20(AaveV3EthereumAssets.wstETH_UNDERLYING).balanceOf(
      address(AaveV3Ethereum.COLLECTOR)
    );
    maxAmountsIn[1] = IERC20(AaveV3EthereumAssets.AAVE_UNDERLYING).balanceOf(
      address(AaveV3Ethereum.COLLECTOR)
    );
    Vault.JoinPoolRequest memory request = Vault.JoinPoolRequest(
      erc20Assets,
      maxAmountsIn,
      abi.encode(0, maxAmountsIn), // 0 = JoinKindInit
      false
    );
    Vault(Addresses.BALANCER_VAULT).joinPool(
      poolId,
      address(AaveV3Ethereum.COLLECTOR),
      address(AaveV3Ethereum.COLLECTOR),
      request
    );
    vm.stopPrank();
  }

  function run() external broadcast {
    _deploy();
  }
}
