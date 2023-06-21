// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.12;

library RightsManager {
  struct Rights {
    bool canPauseSwapping;
    bool canChangeSwapFee;
    bool canChangeWeights;
    bool canAddRemoveTokens;
    bool canWhitelistLPs;
    bool canChangeCap;
  }
}

abstract contract ERC20 {
  function approve(address spender, uint amount) external virtual returns (bool);

  function transfer(address dst, uint amt) external virtual returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint amount
  ) external virtual returns (bool);

  function balanceOf(address whom) external view virtual returns (uint);

  function allowance(address, address) external view virtual returns (uint);
}

abstract contract BalancerOwnable {
  function setController(address controller) external virtual;
}

abstract contract AbstractPool is ERC20, BalancerOwnable {
  function setSwapFee(uint swapFee) external virtual;

  function setPublicSwap(bool public_) external virtual;

  function joinPool(uint poolAmountOut, uint[] calldata maxAmountsIn) external virtual;

  function joinswapExternAmountIn(
    address tokenIn,
    uint tokenAmountIn,
    uint minPoolAmountOut
  ) external virtual returns (uint poolAmountOut);

  function exitPool(uint poolAmountIn, uint[] calldata minAmountsOut) external virtual;
}

abstract contract BPool is AbstractPool {
  function finalize() external virtual;

  function bind(address token, uint balance, uint denorm) external virtual;

  function rebind(address token, uint balance, uint denorm) external virtual;

  function unbind(address token) external virtual;

  function isBound(address t) external view virtual returns (bool);

  function getCurrentTokens() external view virtual returns (address[] memory);

  function getFinalTokens() external view virtual returns (address[] memory);

  function getBalance(address token) external view virtual returns (uint);
}

abstract contract BFactory {
  function newBPool() external virtual returns (BPool);
}

abstract contract BalancerPool is ERC20 {
  function getPoolId() external view virtual returns (bytes32);

  enum JoinKind {
    INIT,
    EXACT_TOKENS_IN_FOR_BPT_OUT
  }
}

abstract contract Vault {
  struct JoinPoolRequest {
    address[] assets;
    uint256[] maxAmountsIn;
    bytes userData;
    bool fromInternalBalance;
  }

  function joinPool(
    bytes32 poolId,
    address sender,
    address recipient,
    JoinPoolRequest calldata request
  ) external virtual;

  function getPoolTokens(
    bytes32 poolId
  ) external view virtual returns (address[] memory, uint[] memory, uint256);
}

abstract contract ConfigurableRightsPool is AbstractPool {
  struct PoolParams {
    string poolTokenSymbol;
    string poolTokenName;
    address[] constituentTokens;
    uint[] tokenBalances;
    uint[] tokenWeights;
    uint swapFee;
  }

  struct CrpParams {
    uint initialSupply;
    uint minimumWeightChangeBlockPeriod;
    uint addTokenTimeLockInBlocks;
  }

  function createPool(
    uint initialSupply,
    uint minimumWeightChangeBlockPeriod,
    uint addTokenTimeLockInBlocks
  ) external virtual;

  function createPool(uint initialSupply) external virtual;

  function setCap(uint newCap) external virtual;

  function updateWeight(address token, uint newWeight) external virtual;

  function updateWeightsGradually(
    uint[] calldata newWeights,
    uint startBlock,
    uint endBlock
  ) external virtual;

  function commitAddToken(address token, uint balance, uint denormalizedWeight) external virtual;

  function applyAddToken() external virtual;

  function removeToken(address token) external virtual;

  function whitelistLiquidityProvider(address provider) external virtual;

  function removeWhitelistedLiquidityProvider(address provider) external virtual;

  function bPool() external view virtual returns (BPool);
}

abstract contract CRPFactory {
  function newCrp(
    address factoryAddress,
    ConfigurableRightsPool.PoolParams calldata params,
    RightsManager.Rights calldata rights
  ) external virtual returns (ConfigurableRightsPool);
}
