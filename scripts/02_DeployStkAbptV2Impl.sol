// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveMisc} from 'aave-address-book/AaveMisc.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {EthereumScript} from 'aave-helpers/ScriptUtils.sol';
import {StakedTokenV3 as StakedTokenV3NoCooldown, IERC20 as IERC20NoCooldown} from 'stk-no-cooldown/contracts/StakedTokenV3.sol';
import {StakedTokenV3} from 'aave-stk-v1-5/contracts/StakedTokenV3.sol';
import {IERC20} from 'aave-stk-v1-5/interfaces/IERC20.sol';
import {IWeightedPool} from '../src/interfaces/IWeightedPool.sol';
import {GenericProposal} from '../src/libs/GenericProposal.sol';

/**
 * @notice Deploys a the implementation for the pool with the bricked initialize.
 */
contract DeployImpl is EthereumScript {
  address public constant ABPT_V1 = 0x41A08648C3766F9F9d85598fF102a08f4ef84F84;
  address internal constant ABPT_V2 = address(0);

  function _deploy(address abptV2) public returns (address, address) {
    return (
      address(
        new StakedTokenV3NoCooldown(
          IERC20NoCooldown(ABPT_V1),
          IERC20NoCooldown(AaveV3EthereumAssets.AAVE_UNDERLYING),
          GenericProposal.UNSTAKE_WINDOW,
          GenericProposal.REWARDS_VAULT,
          GenericProposal.EMISSION_MANAGER,
          GenericProposal.DISTRIBUTION_DURATION
        )
      ),
      address(
        new StakedTokenV3(
          IERC20(abptV2),
          IERC20(AaveV3EthereumAssets.AAVE_UNDERLYING),
          GenericProposal.UNSTAKE_WINDOW,
          GenericProposal.REWARDS_VAULT,
          GenericProposal.EMISSION_MANAGER,
          GenericProposal.DISTRIBUTION_DURATION
        )
      )
    );
  }

  function run() external broadcast {
    require(ABPT_V2 != address(0));
    _deploy(ABPT_V2);
  }
}
