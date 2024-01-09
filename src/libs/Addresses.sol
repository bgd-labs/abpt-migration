// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

library Addresses {
  address internal constant AAVE_ORACLE = 0x547a514d5e3769680Ce22B2361c10Ea13619e8a9;

  address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  address internal constant WSTETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
  address internal constant WSTETH_ORACLE = 0xA9F30e6ED4098e9439B2ac8aEA2d3fc26BcEbb45;

  address internal constant STETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
  address internal constant BALANCER_VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;

  address internal constant ABPT_V1 = 0x41A08648C3766F9F9d85598fF102a08f4ef84F84;
  address internal constant ABPT_V1_BPOOL = 0xC697051d1C6296C24aE3bceF39acA743861D9A81;
  address internal constant STK_ABPT_V1 = 0xa1116930326D21fB917d5A27F1E9943A9595fb47;

  address internal constant ABPT_V2 = 0x3de27EFa2F1AA663Ae5D458857e731c129069F29;
  bytes32 internal constant ABPT_V2_ID =
    0x3de27efa2f1aa663ae5d458857e731c129069f29000200000000000000000588;
}
