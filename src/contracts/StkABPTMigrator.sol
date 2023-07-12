// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {AaveV3Ethereum} from 'aave-address-book/AaveV3Ethereum.sol';
import {AggregatorInterface} from 'aave-address-book/AaveV3.sol';
import {ILido} from '../interfaces/ILido.sol';
import {IWeth} from '../interfaces/IWeth.sol';
import {IWstETH} from '../interfaces/IWstETH.sol';
import {Vault, BPool, BalancerPool, ERC20} from '../interfaces/Actions.sol';
import {Addresses} from '../libs/Addresses.sol';
import {AggregatedStakedTokenV3} from 'aave-stk-v1-5/interfaces/AggregatedStakedTokenV3.sol';

/**
 * @title StkABPTMigrator
 * @author BGD Labs
 * @notice allows migration from abptv1 to abptv2
 */
contract StkABPTMigrator {
  address public immutable STK_ABPT_V2;

  constructor(address stkABPTV2) {
    // infinite approval for putting aave into the lp
    _safeApprove(ERC20(Addresses.AAVE), Addresses.BALANCER_VAULT, type(uint256).max);
    // infinite approval for wrapping stETH
    _safeApprove(ERC20(Addresses.STETH), Addresses.WSTETH, type(uint256).max);
    // infinite approval for pussing wstETH into the lp
    _safeApprove(ERC20(Addresses.WSTETH), Addresses.BALANCER_VAULT, type(uint256).max);
    // infinite approval for putting the lp into stkLP
    _safeApprove(ERC20(Addresses.ABPT_V2), stkABPTV2, type(uint256).max);
    STK_ABPT_V2 = stkABPTV2;
  }

  /**
   * @dev Needed as token will unwrap WETH to ETH, before wrapping into stETH & wstETH
   */
  receive() external payable {}

  function getAbptV1Price() external view {
    address[] memory assets = new address[](2);
    assets[0] = Addresses.AAVE;
    assets[1] = Addresses.WETH;
    uint256[] memory prices = AaveV3Ethereum.ORACLE.getAssetsPrices(assets);
    // bpool get balances
    // bpool get weights
  }

  function getAbptV2Price() external view {
    uint256 wstETHLatestAnswer = uint256(
      AggregatorInterface(Addresses.WSTETH_ORACLE).latestAnswer()
    );
    uint256 aaveLatestAnswer = uint256(AggregatorInterface(Addresses.AAVE_ORACLE).latestAnswer());
  }

  /**
   * migration via approval flow
   * @param amount the amount of stkABPT to migrate
   * @param tokenOutAmountsMin the minimum amount of AAVE/WETH you want to receive for redemption
   * @param poolOutAmountMin the minimum amount of stkABPTV2 tokens you want to receive
   * @param all if true, will migrate all AAVE/WETH. If false will migrate proportionally and send the leftovers to your address.
   */
  function migrateStkABPT(
    uint256 amount,
    uint[] calldata tokenOutAmountsMin,
    uint poolOutAmountMin,
    bool all
  ) external {
    _migrate(amount, tokenOutAmountsMin, poolOutAmountMin, all);
  }

  /**
   * migration via permit
   * @param amount the amount of stkABPT to migrate
   * @param tokenOutAmountsMin the minimum amount of AAVE/WETH you want to receive for redemption
   * @param poolOutAmountMin the minimum amount of stkABPTV2 tokens you want to receive
   * @param all if true, will migrate all AAVE/WETH. If false will migrate proportionally and send the leftovers to your address.
   */
  function migrateStkABPTWithPermit(
    address from,
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s,
    uint[] calldata tokenOutAmountsMin,
    uint poolOutAmountMin,
    bool all
  ) external {
    AggregatedStakedTokenV3(Addresses.STK_ABPT_V1).permit(
      from,
      address(this),
      amount,
      deadline,
      v,
      r,
      s
    );
    _migrate(amount, tokenOutAmountsMin, poolOutAmountMin, all);
  }

  function _migrate(
    uint256 amount,
    uint[] calldata tokenOutAmountsMin,
    uint poolOutAmountMin,
    bool all
  ) internal {
    AggregatedStakedTokenV3(Addresses.STK_ABPT_V1).transferFrom(msg.sender, address(this), amount);
    AggregatedStakedTokenV3(Addresses.STK_ABPT_V1).redeem(address(this), amount);
    if (all) {
      _migrateAll(
        BPool(Addresses.ABPT_V1).balanceOf(address(this)),
        tokenOutAmountsMin,
        poolOutAmountMin
      );
    } else {
      _migrateProportionally(
        BPool(Addresses.ABPT_V1).balanceOf(address(this)),
        tokenOutAmountsMin,
        poolOutAmountMin
      );
    }
    AggregatedStakedTokenV3(STK_ABPT_V2).stake(
      msg.sender,
      BalancerPool(Addresses.ABPT_V2).balanceOf(address(this))
    );
  }

  function _migrateProportionally(
    uint poolInAmount,
    uint[] calldata tokenOutAmountsMin,
    uint poolOutAmountMin
  ) internal {
    // Exit v1 pool
    BPool(Addresses.ABPT_V1).exitPool(poolInAmount, tokenOutAmountsMin);
    (address[] memory outTokens, uint[] memory tokenInAmounts, ) = Vault(Addresses.BALANCER_VAULT)
      .getPoolTokens(Addresses.ABPT_V2_ID);
    // migrate weth to wstETH
    _wethToWesth();
    // Calculate amounts for even join
    // 1) find the lowest UserBalance-to-PoolBalance ratio
    // 2) multiply by this ratio to get in amounts
    uint lowestRatio = type(uint256).max;
    uint lowestRatioToken = 0;

    for (uint i = 0; i < outTokens.length; ++i) {
      uint ratio = (1 ether * ERC20(outTokens[i]).balanceOf(address(this))) / tokenInAmounts[i];
      if (ratio < lowestRatio) {
        lowestRatio = ratio;
        lowestRatioToken = i;
      }
    }
    for (uint i = 0; i < outTokens.length; ++i) {
      // Keep original amount for "bottleneck" token to avoid dust
      if (lowestRatioToken == i) {
        tokenInAmounts[i] = ERC20(outTokens[i]).balanceOf(address(this));
      } else {
        tokenInAmounts[i] = (tokenInAmounts[i] * lowestRatio) / 1 ether;
      }
    }
    // Join v2 pool and transfer v2 BPTs to user
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
    // Send "change" back
    for (uint i = 0; i < outTokens.length; i++) {
      ERC20 token = ERC20(outTokens[i]);
      if (token.balanceOf(address(this)) > 0) {
        require(token.transfer(msg.sender, token.balanceOf(address(this))), 'ERR_TRANSFER_FAILED');
      }
    }
  }

  function _migrateAll(
    uint poolInAmount,
    uint[] calldata tokenOutAmountsMin,
    uint poolOutAmountMin
  ) internal {
    // Exit v1 pool
    BPool(Addresses.ABPT_V1).exitPool(poolInAmount, tokenOutAmountsMin);
    _wethToWesth();
    // Join v2 pool and transfer v2 BPTs to user
    address[] memory outTokens = new address[](2);
    outTokens[0] = Addresses.WSTETH;
    outTokens[1] = Addresses.AAVE;
    uint[] memory tokenInAmounts = new uint[](outTokens.length);
    for (uint i = 0; i < outTokens.length; ++i) {
      tokenInAmounts[i] = ERC20(outTokens[i]).balanceOf(address(this));
    }

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
  }

  function _wethToWesth() internal {
    // Unwrap WETH to ETH
    uint256 wethBalance = ERC20(Addresses.WETH).balanceOf(address(this));
    IWeth(Addresses.WETH).withdraw(wethBalance);
    // supply ETH to stETH
    ILido(Addresses.STETH).submit{value: wethBalance}(address(0));
    // wrap stETH to wstETH
    IWstETH(Addresses.WSTETH).wrap(ERC20(Addresses.STETH).balanceOf(address(this)));
  }

  // --- Internals ---FrÃ©land, 68240, Franceranrupt

  function _safeApprove(ERC20 token, address spender, uint amount) internal {
    if (token.allowance(address(this), spender) > 0) {
      token.approve(spender, 0);
    }
    token.approve(spender, amount);
  }
}
