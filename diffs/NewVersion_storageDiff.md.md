```diff
diff --git a/reports/currentStakedToken.md b/reports/newStakedToken.md
index 53daeac..8586d9a 100644
--- a/reports/currentStakedToken.md
+++ b/reports/newStakedToken.md
@@ -1,29 +1,25 @@
 |Name|Type|Slot|Offset|Bytes|Contract|
 |-|-|-|-|-|-|
-| _balances                        | mapping(address => uint256)                                                            | 0    | 0      | 32    |StakedTokenV3.sol:StakedTokenV3|
-| _allowances                      | mapping(address => mapping(address => uint256))                                        | 1    | 0      | 32    |StakedTokenV3.sol:StakedTokenV3|
-| _totalSupply                     | uint256                                                                                | 2    | 0      | 32    |StakedTokenV3.sol:StakedTokenV3|
-| _name                            | string                                                                                 | 3    | 0      | 32    |StakedTokenV3.sol:StakedTokenV3|
-| _symbol                          | string                                                                                 | 4    | 0      | 32    |StakedTokenV3.sol:StakedTokenV3|
-| _decimals                        | uint8                                                                                  | 5    | 0      | 1     |StakedTokenV3.sol:StakedTokenV3|
-| _votingSnapshots                 | mapping(address => mapping(uint256 => struct GovernancePowerDelegationERC20.Snapshot)) | 6    | 0      | 32    |StakedTokenV3.sol:StakedTokenV3|
-| _votingSnapshotsCounts           | mapping(address => uint256)                                                            | 7    | 0      | 32    |StakedTokenV3.sol:StakedTokenV3|
-| _aaveGovernance                  | contract ITransferHook                                                                 | 8    | 0      | 20    |StakedTokenV3.sol:StakedTokenV3|
-| lastInitializedRevision          | uint256                                                                                | 9    | 0      | 32    |StakedTokenV3.sol:StakedTokenV3|
-| ______gap                        | uint256[50]                                                                            | 10   | 0      | 1600  |StakedTokenV3.sol:StakedTokenV3|
-| assets                           | mapping(address => struct AaveDistributionManager.AssetData)                           | 60   | 0      | 32    |StakedTokenV3.sol:StakedTokenV3|
-| stakerRewardsToClaim             | mapping(address => uint256)                                                            | 61   | 0      | 32    |StakedTokenV3.sol:StakedTokenV3|
-| stakersCooldowns                 | mapping(address => struct IStakedTokenV2.CooldownSnapshot)                             | 62   | 0      | 32    |StakedTokenV3.sol:StakedTokenV3|
-| _votingDelegates                 | mapping(address => address)                                                            | 63   | 0      | 32    |StakedTokenV3.sol:StakedTokenV3|
-| _propositionPowerSnapshots       | mapping(address => mapping(uint256 => struct GovernancePowerDelegationERC20.Snapshot)) | 64   | 0      | 32    |StakedTokenV3.sol:StakedTokenV3|
-| _propositionPowerSnapshotsCounts | mapping(address => uint256)                                                            | 65   | 0      | 32    |StakedTokenV3.sol:StakedTokenV3|
-| _propositionPowerDelegates       | mapping(address => address)                                                            | 66   | 0      | 32    |StakedTokenV3.sol:StakedTokenV3|
-| DOMAIN_SEPARATOR                 | bytes32                                                                                | 67   | 0      | 32    |StakedTokenV3.sol:StakedTokenV3|
-| _nonces                          | mapping(address => uint256)                                                            | 68   | 0      | 32    |StakedTokenV3.sol:StakedTokenV3|
-| _admins                          | mapping(uint256 => address)                                                            | 69   | 0      | 32    |StakedTokenV3.sol:StakedTokenV3|
-| _pendingAdmins                   | mapping(uint256 => address)                                                            | 70   | 0      | 32    |StakedTokenV3.sol:StakedTokenV3|
-| ______gap                        | uint256[8]                                                                             | 71   | 0      | 256   |StakedTokenV3.sol:StakedTokenV3|
-| _cooldownSeconds                 | uint256                                                                                | 79   | 0      | 32    |StakedTokenV3.sol:StakedTokenV3|
-| _maxSlashablePercentage          | uint256                                                                                | 80   | 0      | 32    |StakedTokenV3.sol:StakedTokenV3|
-| _currentExchangeRate             | uint216                                                                                | 81   | 0      | 27    |StakedTokenV3.sol:StakedTokenV3|
-| inPostSlashingPeriod             | bool                                                                                   | 81   | 27     | 1     |StakedTokenV3.sol:StakedTokenV3|
\ No newline at end of file
+| _balances                           | mapping(address => struct BaseAaveToken.DelegationAwareBalance) | 0    | 0      | 32    |StakedTokenV3.sol:StakedTokenV3|
+| _allowances                         | mapping(address => mapping(address => uint256))                 | 1    | 0      | 32    |StakedTokenV3.sol:StakedTokenV3|
+| _totalSupply                        | uint256                                                         | 2    | 0      | 32    |StakedTokenV3.sol:StakedTokenV3|
+| _name                               | string                                                          | 3    | 0      | 32    |StakedTokenV3.sol:StakedTokenV3|
+| _symbol                             | string                                                          | 4    | 0      | 32    |StakedTokenV3.sol:StakedTokenV3|
+| ______DEPRECATED_OLD_ERC20_DECIMALS | uint8                                                           | 5    | 0      | 1     |StakedTokenV3.sol:StakedTokenV3|
+| __________DEPRECATED_GOV_V2_PART    | uint256[3]                                                      | 6    | 0      | 96    |StakedTokenV3.sol:StakedTokenV3|
+| lastInitializedRevision             | uint256                                                         | 9    | 0      | 32    |StakedTokenV3.sol:StakedTokenV3|
+| ______gap                           | uint256[50]                                                     | 10   | 0      | 1600  |StakedTokenV3.sol:StakedTokenV3|
+| assets                              | mapping(address => struct AaveDistributionManager.AssetData)    | 60   | 0      | 32    |StakedTokenV3.sol:StakedTokenV3|
+| stakerRewardsToClaim                | mapping(address => uint256)                                     | 61   | 0      | 32    |StakedTokenV3.sol:StakedTokenV3|
+| stakersCooldowns                    | mapping(address => struct IStakedTokenV2.CooldownSnapshot)      | 62   | 0      | 32    |StakedTokenV3.sol:StakedTokenV3|
+| ______DEPRECATED_FROM_STK_AAVE_V2   | uint256[5]                                                      | 63   | 0      | 160   |StakedTokenV3.sol:StakedTokenV3|
+| _nonces                             | mapping(address => uint256)                                     | 68   | 0      | 32    |StakedTokenV3.sol:StakedTokenV3|
+| _admins                             | mapping(uint256 => address)                                     | 69   | 0      | 32    |StakedTokenV3.sol:StakedTokenV3|
+| _pendingAdmins                      | mapping(uint256 => address)                                     | 70   | 0      | 32    |StakedTokenV3.sol:StakedTokenV3|
+| _votingDelegatee                    | mapping(address => address)                                     | 71   | 0      | 32    |StakedTokenV3.sol:StakedTokenV3|
+| _propositionDelegatee               | mapping(address => address)                                     | 72   | 0      | 32    |StakedTokenV3.sol:StakedTokenV3|
+| ______gap                           | uint256[6]                                                      | 73   | 0      | 192   |StakedTokenV3.sol:StakedTokenV3|
+| _cooldownSeconds                    | uint256                                                         | 79   | 0      | 32    |StakedTokenV3.sol:StakedTokenV3|
+| _maxSlashablePercentage             | uint256                                                         | 80   | 0      | 32    |StakedTokenV3.sol:StakedTokenV3|
+| _currentExchangeRate                | uint216                                                         | 81   | 0      | 27    |StakedTokenV3.sol:StakedTokenV3|
+| inPostSlashingPeriod                | bool                                                            | 81   | 27     | 1     |StakedTokenV3.sol:StakedTokenV3|
\ No newline at end of file
```
