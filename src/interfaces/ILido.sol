// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface ILido {
  function submit(address _referral) external payable returns (uint256);
}
