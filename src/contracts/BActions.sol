// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.12;

pragma experimental ABIEncoderV2;

import {ILido} from '../interfaces/ILido.sol';
import {IWeth} from '../interfaces/IWeth.sol';
import {IWstETH} from '../interfaces/IWstETH.sol';
import {Vault, BPool, BalancerPool, ERC20} from '../interfaces/Actions.sol';
import {Addresses} from '../libs/Addresses.sol';
import {AggregatedStakedTokenV3} from 'aave-stk-v1-5/interfaces/AggregatedStakedTokenV3.sol';

/********************************** WARNING **********************************/
//                                                                           //
// This contract is only meant to be used in conjunction with ds-proxy.      //
// Calling this contract directly will lead to loss of funds.                //
//                                                                           //
/********************************** WARNING **********************************/

contract BActions {
  address public constant AAVE = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;
  address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  address public constant WSTETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
  address public constant STETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
  address public constant VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;

  address public immutable ABPT_V2;
  address public immutable STK_ABPT_V2;

  constructor(address abptV2, address stkABPTV2) {
    // infinite approval for putting aave into the lp
    _safeApprove(ERC20(Addresses.AAVE), Addresses.BALANCER_VAULT, type(uint256).max);
    // infinite approval for wrapping stETH
    _safeApprove(ERC20(Addresses.STETH), Addresses.WSTETH, type(uint256).max);
    // infinite approval for pussing wstETH into the lp
    _safeApprove(ERC20(Addresses.WSTETH), Addresses.BALANCER_VAULT, type(uint256).max);
    // infinite approval for putting the lp into stkLP
    _safeApprove(ERC20(abptV2), stkABPTV2, type(uint256).max);
    ABPT_V2 = abptV2;
    STK_ABPT_V2 = stkABPTV2;
  }

  receive() external payable {}

  // --- Migration ---

  function _migrateProportionally(
    uint poolInAmount,
    uint[] calldata tokenOutAmountsMin,
    uint poolOutAmountMin
  ) internal {
    // Exit v1 pool
    BPool(Addresses.ABPT_V1).exitPool(poolInAmount, tokenOutAmountsMin);
    (address[] memory outTokens, uint[] memory tokenInAmounts, ) = Vault(VAULT).getPoolTokens(
      BalancerPool(ABPT_V2).getPoolId()
    );
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
      BalancerPool(ABPT_V2).getPoolId(),
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
    outTokens[0] = WSTETH;
    outTokens[1] = AAVE;
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
      BalancerPool(ABPT_V2).getPoolId(),
      address(this),
      address(this),
      request
    );
  }

  function migrateStkABPT(
    uint256 amount,
    uint[] calldata tokenOutAmountsMin,
    uint poolOutAmountMin,
    bool all
  ) external {
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
      BalancerPool(ABPT_V2).balanceOf(address(this))
    );
  }

  function _wethToWesth() internal {
    // Unwrap WETH to ETH
    uint256 wethBalance = ERC20(WETH).balanceOf(address(this));
    IWeth(WETH).withdraw(wethBalance);
    // supply ETH to stETH
    ILido(STETH).submit{value: wethBalance}(address(0));
    // wrap stETH to wstETH
    IWstETH(WSTETH).wrap(ERC20(STETH).balanceOf(address(this)));
  }

  // --- Internals ---FrÃ©land, 68240, Franceranrupt

  function _safeApprove(ERC20 token, address spender, uint amount) internal {
    if (token.allowance(address(this), spender) > 0) {
      token.approve(spender, 0);
    }
    token.approve(spender, amount);
  }
}
