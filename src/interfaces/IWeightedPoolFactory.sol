// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {IRateProvider} from './IRateProvider.sol';

interface IWeightedPoolFactory {
  function create(
    string memory name,
    string memory symbol,
    IERC20[] memory tokens,
    uint256[] memory normalizedWeights,
    IRateProvider[] memory rateProviders,
    uint256 swapFeePercentage,
    address owner,
    bytes32 salt
  ) external returns (address);
}
