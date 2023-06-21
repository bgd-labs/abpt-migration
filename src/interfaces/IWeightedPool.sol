// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IWeightedPool {
  function balanceOf(address account) external view returns (uint256);

  function getPoolId() external view returns (bytes32);
}
