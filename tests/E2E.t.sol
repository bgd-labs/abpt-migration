// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

contract E2E is Test {
  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'), 17514320);
  }

  function testE2E() public {}
}
