// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MiscEthereum} from 'aave-address-book/MiscEthereum.sol';
import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';

library GenericProposal {
  address public constant SLASHING_ADMIN = GovernanceV3Ethereum.EXECUTOR_LVL_1;

  address public constant COOLDOWN_ADMIN = GovernanceV3Ethereum.EXECUTOR_LVL_1;

  address public constant CLAIM_HELPER = GovernanceV3Ethereum.EXECUTOR_LVL_1;

  address public constant REWARDS_VAULT = MiscEthereum.ECOSYSTEM_RESERVE;

  address public constant EMISSION_MANAGER = GovernanceV3Ethereum.EXECUTOR_LVL_1;

  uint256 public constant MAX_SLASHING = 3000; // 30%

  uint256 public constant COOLDOWN_SECONDS = 1728000; // 20 days

  uint256 public constant UNSTAKE_WINDOW = 172800; // 2 days

  uint128 public constant DISTRIBUTION_DURATION = 3155692600; // 100 years
}
