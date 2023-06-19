// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {IERC20} from 'aave-stk-v1-5/interfaces/IERC20.sol';

interface IWeightedPool2TokensFactory {
  function create(
    string memory name,
    string memory symbol,
    IERC20[] memory tokens,
    uint256[] memory weights,
    uint256 swapFeePercentage,
    bool oracleEnabled,
    address owner
  ) external returns (address);
}
