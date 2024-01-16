// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';
import {AaveV3Ethereum} from 'aave-address-book/AaveV3Ethereum.sol';
import {AggregatorInterface} from 'aave-address-book/AaveV3.sol';
import {ILido} from '../interfaces/ILido.sol';
import {IWeth} from '../interfaces/IWeth.sol';
import {IWstETH} from '../interfaces/IWstETH.sol';
import {Vault, BPool, BalancerPool, ERC20} from '../interfaces/Actions.sol';
import {Addresses} from '../libs/Addresses.sol';
import {IAggregatedStakeToken} from 'stake-token/contracts/IAggregatedStakeToken.sol';
import {Rescuable} from 'solidity-utils/contracts/utils/Rescuable.sol';
import {AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {AaveSafetyModule} from 'aave-address-book/AaveSafetyModule.sol';

/**
 * @title StkABPTMigrator
 * @author BGD Labs
 * @notice allows migration from abptv1 to abptv2
 */
contract StkABPTMigrator is Rescuable {
  address public immutable STK_ABPT_V2;

  constructor(address stkABPTV2) {
    // infinite approval for putting aave into the lp
    _safeApprove(
      ERC20(AaveV3EthereumAssets.AAVE_UNDERLYING),
      Addresses.BALANCER_VAULT,
      type(uint256).max
    );
    // infinite approval for wrapping stETH
    _safeApprove(ERC20(Addresses.STETH), AaveV3EthereumAssets.wstETH_UNDERLYING, type(uint256).max);
    // infinite approval for depositing wstETH into the LP
    _safeApprove(
      ERC20(AaveV3EthereumAssets.wstETH_UNDERLYING),
      Addresses.BALANCER_VAULT,
      type(uint256).max
    );
    // infinite approval for putting the lp into stkLP
    _safeApprove(ERC20(Addresses.ABPT_V2), stkABPTV2, type(uint256).max);
    STK_ABPT_V2 = stkABPTV2;
  }

  /**
   * @dev Needed as token will unwrap WETH to ETH, before wrapping into stETH & wstETH
   */
  receive() external payable {}

  /**
   * allow the short executor to rescue tokens
   */
  function whoCanRescue() public pure override returns (address) {
    return GovernanceV3Ethereum.EXECUTOR_LVL_1;
  }

  /**
   * migration via approval flow
   * @param amount the amount of stkABPT to migrate
   * @param tokenOutAmountsMin the minimum amount of AAVE/WETH you want to receive for redemption
   * @param poolOutAmountMin the minimum amount of stkABPTV2 tokens you want to receive
   */
  function migrateStkABPT(
    uint256 amount,
    uint256[] calldata tokenOutAmountsMin,
    uint256 poolOutAmountMin
  ) external {
    _migrate(amount, tokenOutAmountsMin, poolOutAmountMin);
  }

  /**
   * migration via permit
   * @param amount the amount of stkABPT to migrate
   * @param tokenOutAmountsMin the minimum amount of AAVE/WETH you want to receive for redemption
   * @param poolOutAmountMin the minimum amount of stkABPTV2 tokens you want to receive
   */
  function migrateStkABPTWithPermit(
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s,
    uint256[] calldata tokenOutAmountsMin,
    uint256 poolOutAmountMin
  ) external {
    try
      IAggregatedStakeToken(AaveSafetyModule.STK_ABPT).permit(
        msg.sender,
        address(this),
        amount,
        deadline,
        v,
        r,
        s
      )
    {} catch {}
    _migrate(amount, tokenOutAmountsMin, poolOutAmountMin);
  }

  function _migrate(
    uint256 amount,
    uint256[] calldata tokenOutAmountsMin,
    uint256 poolOutAmountMin
  ) internal {
    IAggregatedStakeToken(AaveSafetyModule.STK_ABPT).transferFrom(
      msg.sender,
      address(this),
      amount
    );
    IAggregatedStakeToken(AaveSafetyModule.STK_ABPT).redeem(address(this), amount);
    uint256 poolInAmount = BPool(Addresses.ABPT_V1).balanceOf(address(this));
    // Exit v1 pool
    uint256 wethBalanceBefore = ERC20(AaveV3EthereumAssets.WETH_UNDERLYING).balanceOf(
      address(this)
    );
    uint256 aaveBalanceBefore = ERC20(AaveV3EthereumAssets.AAVE_UNDERLYING).balanceOf(
      address(this)
    );

    BPool(Addresses.ABPT_V1).exitPool(poolInAmount, tokenOutAmountsMin);

    uint256 wethBalanceAfter = ERC20(AaveV3EthereumAssets.WETH_UNDERLYING).balanceOf(address(this));
    uint256 aaveBalanceAfter = ERC20(AaveV3EthereumAssets.AAVE_UNDERLYING).balanceOf(address(this));

    // Join v2 pool and transfer v2 BPTs to user
    address[] memory outTokens = new address[](2);
    outTokens[0] = AaveV3EthereumAssets.wstETH_UNDERLYING;
    outTokens[1] = AaveV3EthereumAssets.AAVE_UNDERLYING;
    uint256[] memory tokenInAmounts = new uint[](outTokens.length);
    tokenInAmounts[0] = _wethToWesth(wethBalanceAfter - wethBalanceBefore);
    tokenInAmounts[1] = aaveBalanceAfter - aaveBalanceBefore;

    bytes memory userData = abi.encode(
      BalancerPool.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT,
      tokenInAmounts,
      poolOutAmountMin
    );
    Vault.JoinPoolRequest memory request = Vault.JoinPoolRequest(
      outTokens,
      tokenInAmounts,
      userData,
      false
    );
    Vault(Addresses.BALANCER_VAULT).joinPool(
      Addresses.ABPT_V2_ID,
      address(this),
      address(this),
      request
    );

    IAggregatedStakeToken(STK_ABPT_V2).stake(
      msg.sender,
      BalancerPool(Addresses.ABPT_V2).balanceOf(address(this))
    );
  }

  function _wethToWesth(uint256 amount) internal returns (uint256) {
    // Unwrap WETH to ETH
    IWeth(AaveV3EthereumAssets.WETH_UNDERLYING).withdraw(amount);
    // supply ETH to stETH
    uint256 stETHBefore = ERC20(Addresses.STETH).balanceOf(address(this));
    ILido(Addresses.STETH).submit{value: amount}(address(0));
    uint256 stETHAfter = ERC20(Addresses.STETH).balanceOf(address(this));
    // wrap stETH to wstETH
    return IWstETH(AaveV3EthereumAssets.wstETH_UNDERLYING).wrap(stETHAfter - stETHBefore);
  }

  function _safeApprove(ERC20 token, address spender, uint256 amount) internal {
    if (token.allowance(address(this), spender) > 0) {
      token.approve(spender, 0);
    }
    token.approve(spender, amount);
  }
}
