// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/// @notice A simple version of the WStETH interface allowing to wrap and get exchange rate
interface IWstETH {
  /**
   * @notice Wraps stETH to WStETH
   * @param stETHAmount amount to wrap
   * @return an amount of WStETH received
   */
  function wrap(uint256 stETHAmount) external returns (uint256);

  /**
   * @notice Estimates an amount of WStETH on wrap
   * @param stETHAmount amount to wrap
   * @return an amount of WStETH which will be received
   */
  function getWstETHByStETH(uint256 stETHAmount) external view returns (uint256);
}
