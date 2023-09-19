# Aave StkABPTV1 -> Aave StkABPTV2 migration

## About this repository

This repository consists out of 4 independent contracts:

### 1. [BalancerSharedPoolPriceProvider](./src/contracts/BalancerSharedPoolPriceProvider.sol)

The `BalancerSharedPoolPriceProvider` is a price provider for balancer v1 pools.
The price provider will return the price as arithmetic mean when the pool is in equilibrium and as weighted geometric mean when the pool is imbalanced. This calculation helps to determine a manipulation resistant fair market price.
This price provider will provide the price for abpt shares determined in USD, based on the AaveOracle prices and is intended to be used to determine the fair market value of a users shares.

### 2. [BalancerV2SharedPoolPriceProvider](./src/contracts/BalancerV2SharedPoolPriceProvider.sol)

The `BalancerV2SharedPoolPriceProvider` is a price provider for balancer v2 pools.
The price calculation is analog to `BalancerSharedPoolPriceProvider`.

### 3. [StkABPTMigrator](./src/contracts/StkABPTMigrator.sol)

The `StkABPTMigrator` is a migration contract that allows migrating stkABPT to stkABPTv2.
The contract offers a `migrateStkABPT` and a `migrateStkABPTWithPermit` external function that allows migrating funds within the safety module.

The contract call will:
1. pull funds from stkABPT
2. pull funds from abpt
3. wrap weth into wstETH
4. deposit into abptv2
5. deposit into stkabptv2

These methods allow two types of migration:
1. exact migration
2. proportional migration

In the exact migration path
```solidity
migrateStkABPT(
    uint256 amount,
    [0,0],
    minAmountOut, // slippage control
    true // all
)
```

The amount is withdrawn from stkABPT and fully deposited into stkABPTv2. `minAmountOut` in this case acts as slippage control and should be calculated as `((amount * uint256(abptOracle.latestAnswer())) / uint256(abptv2Oracle.latestAnswer())) * slippage`. By making slippage sufficiently small (e.g. `0.01%`), the swap will revert if one of the pools is highly imbalanced. As long as the pools have reasonable liquidity, we expect this path to be preferrable as arbitrage bots will keep the pool close to equilibrium.

In the proportional migration path:
```solidity
migrateStkABPT(
    uint256 amount,
    tokenOutAmountsMin,
    minAmountOut, // slippage control
    false // all
)
```

The slippage control is on both the `tokenOutAmountsMin` and `minAmountsOut`. Instead of joining with the full balance withdrawn from v1, the join on v2 will be proportional to reach equlibrium. The remaining funds will be sent back to the sender.

### 4. [ProposalPayload](./src/contracts/ProposalPayload.sol)

This contract is intended to be used as the proposal payload to initiate the migration process.
The payload does multiple actions:
1. stop liquidity incentives on stkabptv1
2. upgrade the token implementation to allow withdrawals without cooldown
3. create the nem stkabptv2 sm
4. start liquidity incentives on stkabptv2

## Development

This project uses [Foundry](https://getfoundry.sh). See the [book](https://book.getfoundry.sh/getting-started/installation.html) for detailed instructions on how to install and use Foundry.
The template ships with sensible default so you can use default `foundry` commands without resorting to `MakeFile`.

### Setup

```sh
cp .env.example .env
forge install
```

### Test

```sh
forge test
```