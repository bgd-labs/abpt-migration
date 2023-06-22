// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import 'forge-std/Test.sol';

library SigUtils {
  bytes32 public constant PERMIT_TYPEHASH =
    keccak256('Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)');

  struct Permit {
    address owner;
    address spender;
    uint256 value;
    uint256 nonce;
    uint256 deadline;
  }

  // computes the hash of a permit
  function getStructHash(Permit memory _permit) internal pure returns (bytes32) {
    return
      keccak256(
        abi.encode(
          PERMIT_TYPEHASH,
          _permit.owner,
          _permit.spender,
          _permit.value,
          _permit.nonce,
          _permit.deadline
        )
      );
  }

  // computes the hash of the fully encoded EIP-712 message for the domain, which can be used to recover the signer
  function getPermitTypedDataHash(
    Permit memory _permit,
    bytes32 domainSeparator
  ) public pure returns (bytes32) {
    return
      keccak256(
        abi.encodePacked(
          '\x19\x01',
          domainSeparator,
          keccak256(
            abi.encode(
              PERMIT_TYPEHASH,
              _permit.owner,
              _permit.spender,
              _permit.value,
              _permit.nonce,
              _permit.deadline
            )
          )
        )
      );
  }

  // computes the hash of the fully encoded EIP-712 message for the domain, which can be used to recover the signer
  function getTypedDataHash(
    Permit memory permit,
    bytes32 domainSeperator
  ) public pure returns (bytes32) {
    return keccak256(abi.encodePacked('\x19\x01', domainSeperator, getStructHash(permit)));
  }
}
