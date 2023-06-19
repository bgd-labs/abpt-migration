// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveMisc} from 'aave-address-book/AaveMisc.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';

library GenericProposal {
  address public constant SLASHING_ADMIN = AaveGovernanceV2.SHORT_EXECUTOR;

  address public constant COOLDOWN_ADMIN = AaveGovernanceV2.SHORT_EXECUTOR;

  address public constant CLAIM_HELPER = AaveGovernanceV2.SHORT_EXECUTOR;

  address public constant REWARDS_VAULT = AaveMisc.ECOSYSTEM_RESERVE;

  address public constant EMISSION_MANAGER = AaveGovernanceV2.SHORT_EXECUTOR;

  uint256 public constant MAX_SLASHING = 3000; // 30%

  uint256 public constant COOLDOWN_SECONDS = 1728000; // 20 days

  uint256 public constant UNSTAKE_WINDOW = 172800; // 2 days

  uint128 public constant DISTRIBUTION_DURATION = 3155692600; // 100 years
}
