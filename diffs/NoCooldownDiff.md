```diff
diff --git a/src/etherscan/mainnet_0x9921c8cea5815364d0f8350e6cbe9042A92448c9/StakedTokenV3/src/contracts/AaveDistributionManager.sol b/src/etherscan/sepolia_0xd1B3E25fD7C8AE7CADDC6F71b461b79CD4ddcFa3/StakedTokenV3/lib/stk-no-cooldown/src/contracts/AaveDistributionManager.sol
similarity index 100%
rename from src/etherscan/mainnet_0x9921c8cea5815364d0f8350e6cbe9042A92448c9/StakedTokenV3/src/contracts/AaveDistributionManager.sol
rename to src/etherscan/sepolia_0xd1B3E25fD7C8AE7CADDC6F71b461b79CD4ddcFa3/StakedTokenV3/lib/stk-no-cooldown/src/contracts/AaveDistributionManager.sol
diff --git a/src/etherscan/mainnet_0x9921c8cea5815364d0f8350e6cbe9042A92448c9/StakedTokenV3/src/contracts/StakedTokenV2.sol b/src/etherscan/sepolia_0xd1B3E25fD7C8AE7CADDC6F71b461b79CD4ddcFa3/StakedTokenV3/lib/stk-no-cooldown/src/contracts/StakedTokenV2.sol
similarity index 100%
rename from src/etherscan/mainnet_0x9921c8cea5815364d0f8350e6cbe9042A92448c9/StakedTokenV3/src/contracts/StakedTokenV2.sol
rename to src/etherscan/sepolia_0xd1B3E25fD7C8AE7CADDC6F71b461b79CD4ddcFa3/StakedTokenV3/lib/stk-no-cooldown/src/contracts/StakedTokenV2.sol
diff --git a/src/etherscan/mainnet_0x9921c8cea5815364d0f8350e6cbe9042A92448c9/StakedTokenV3/src/contracts/StakedTokenV3.sol b/src/etherscan/sepolia_0xd1B3E25fD7C8AE7CADDC6F71b461b79CD4ddcFa3/StakedTokenV3/lib/stk-no-cooldown/src/contracts/StakedTokenV3.sol
similarity index 96%
rename from src/etherscan/mainnet_0x9921c8cea5815364d0f8350e6cbe9042A92448c9/StakedTokenV3/src/contracts/StakedTokenV3.sol
rename to src/etherscan/sepolia_0xd1B3E25fD7C8AE7CADDC6F71b461b79CD4ddcFa3/StakedTokenV3/lib/stk-no-cooldown/src/contracts/StakedTokenV3.sol
index f5b5656..fe7edb9 100644
--- a/src/etherscan/mainnet_0x9921c8cea5815364d0f8350e6cbe9042A92448c9/StakedTokenV3/src/contracts/StakedTokenV3.sol
+++ b/src/etherscan/sepolia_0xd1B3E25fD7C8AE7CADDC6F71b461b79CD4ddcFa3/StakedTokenV3/lib/stk-no-cooldown/src/contracts/StakedTokenV3.sol
@@ -87,7 +87,7 @@ contract StakedTokenV3 is StakedTokenV2, IStakedTokenV3, RoleManager, IAaveDistr
    * @return The revision
    */
   function REVISION() public pure virtual returns (uint256) {
-    return 3;
+    return 4;
   }
 
   /**
@@ -101,20 +101,8 @@ contract StakedTokenV3 is StakedTokenV2, IStakedTokenV3, RoleManager, IAaveDistr
   /**
    * @dev Called by the proxy contract
    */
-  function initialize(
-    address slashingAdmin,
-    address cooldownPauseAdmin,
-    address claimHelper,
-    uint256 maxSlashablePercentage,
-    uint256 cooldownSeconds
-  ) external virtual initializer {
-    _initialize(
-      slashingAdmin,
-      cooldownPauseAdmin,
-      claimHelper,
-      maxSlashablePercentage,
-      cooldownSeconds
-    );
+  function initialize() external virtual initializer {
+    inPostSlashingPeriod = true;
   }
 
   function _initialize(
@@ -420,7 +408,7 @@ contract StakedTokenV3 is StakedTokenV2, IStakedTokenV3, RoleManager, IAaveDistr
     CooldownSnapshot memory cooldownSnapshot = stakersCooldowns[from];
     if (!inPostSlashingPeriod) {
       require(
-        (block.timestamp > cooldownSnapshot.timestamp + _cooldownSeconds),
+        (block.timestamp >= cooldownSnapshot.timestamp + _cooldownSeconds),
         'INSUFFICIENT_COOLDOWN'
       );
       require(
@@ -494,7 +482,7 @@ contract StakedTokenV3 is StakedTokenV2, IStakedTokenV3, RoleManager, IAaveDistr
         if (balanceOfFrom == amount) {
           delete stakersCooldowns[from];
         } else if (balanceOfFrom - amount < previousSenderCooldown.amount) {
-          stakersCooldowns[from].amount = uint184(balanceOfFrom - amount);
+          stakersCooldowns[from].amount = uint216(balanceOfFrom - amount);
         }
       }
     }
diff --git a/src/etherscan/mainnet_0x9921c8cea5815364d0f8350e6cbe9042A92448c9/StakedTokenV3/src/interfaces/IAaveDistributionManager.sol b/src/etherscan/sepolia_0xd1B3E25fD7C8AE7CADDC6F71b461b79CD4ddcFa3/StakedTokenV3/lib/stk-no-cooldown/src/interfaces/IAaveDistributionManager.sol
similarity index 100%
rename from src/etherscan/mainnet_0x9921c8cea5815364d0f8350e6cbe9042A92448c9/StakedTokenV3/src/interfaces/IAaveDistributionManager.sol
rename to src/etherscan/sepolia_0xd1B3E25fD7C8AE7CADDC6F71b461b79CD4ddcFa3/StakedTokenV3/lib/stk-no-cooldown/src/interfaces/IAaveDistributionManager.sol
diff --git a/src/etherscan/mainnet_0x9921c8cea5815364d0f8350e6cbe9042A92448c9/StakedTokenV3/src/interfaces/IERC20.sol b/src/etherscan/sepolia_0xd1B3E25fD7C8AE7CADDC6F71b461b79CD4ddcFa3/StakedTokenV3/lib/stk-no-cooldown/src/interfaces/IERC20.sol
similarity index 100%
rename from src/etherscan/mainnet_0x9921c8cea5815364d0f8350e6cbe9042A92448c9/StakedTokenV3/src/interfaces/IERC20.sol
rename to src/etherscan/sepolia_0xd1B3E25fD7C8AE7CADDC6F71b461b79CD4ddcFa3/StakedTokenV3/lib/stk-no-cooldown/src/interfaces/IERC20.sol
diff --git a/src/etherscan/mainnet_0x9921c8cea5815364d0f8350e6cbe9042A92448c9/StakedTokenV3/src/interfaces/IERC20Metadata.sol b/src/etherscan/sepolia_0xd1B3E25fD7C8AE7CADDC6F71b461b79CD4ddcFa3/StakedTokenV3/lib/stk-no-cooldown/src/interfaces/IERC20Metadata.sol
similarity index 100%
rename from src/etherscan/mainnet_0x9921c8cea5815364d0f8350e6cbe9042A92448c9/StakedTokenV3/src/interfaces/IERC20Metadata.sol
rename to src/etherscan/sepolia_0xd1B3E25fD7C8AE7CADDC6F71b461b79CD4ddcFa3/StakedTokenV3/lib/stk-no-cooldown/src/interfaces/IERC20Metadata.sol
diff --git a/src/etherscan/mainnet_0x9921c8cea5815364d0f8350e6cbe9042A92448c9/StakedTokenV3/src/interfaces/IGovernancePowerDelegationToken.sol b/src/etherscan/sepolia_0xd1B3E25fD7C8AE7CADDC6F71b461b79CD4ddcFa3/StakedTokenV3/lib/stk-no-cooldown/src/interfaces/IGovernancePowerDelegationToken.sol
similarity index 100%
rename from src/etherscan/mainnet_0x9921c8cea5815364d0f8350e6cbe9042A92448c9/StakedTokenV3/src/interfaces/IGovernancePowerDelegationToken.sol
rename to src/etherscan/sepolia_0xd1B3E25fD7C8AE7CADDC6F71b461b79CD4ddcFa3/StakedTokenV3/lib/stk-no-cooldown/src/interfaces/IGovernancePowerDelegationToken.sol
diff --git a/src/etherscan/mainnet_0x9921c8cea5815364d0f8350e6cbe9042A92448c9/StakedTokenV3/src/interfaces/IStakedTokenV2.sol b/src/etherscan/sepolia_0xd1B3E25fD7C8AE7CADDC6F71b461b79CD4ddcFa3/StakedTokenV3/lib/stk-no-cooldown/src/interfaces/IStakedTokenV2.sol
similarity index 100%
rename from src/etherscan/mainnet_0x9921c8cea5815364d0f8350e6cbe9042A92448c9/StakedTokenV3/src/interfaces/IStakedTokenV2.sol
rename to src/etherscan/sepolia_0xd1B3E25fD7C8AE7CADDC6F71b461b79CD4ddcFa3/StakedTokenV3/lib/stk-no-cooldown/src/interfaces/IStakedTokenV2.sol
diff --git a/src/etherscan/mainnet_0x9921c8cea5815364d0f8350e6cbe9042A92448c9/StakedTokenV3/src/interfaces/IStakedTokenV3.sol b/src/etherscan/sepolia_0xd1B3E25fD7C8AE7CADDC6F71b461b79CD4ddcFa3/StakedTokenV3/lib/stk-no-cooldown/src/interfaces/IStakedTokenV3.sol
similarity index 100%
rename from src/etherscan/mainnet_0x9921c8cea5815364d0f8350e6cbe9042A92448c9/StakedTokenV3/src/interfaces/IStakedTokenV3.sol
rename to src/etherscan/sepolia_0xd1B3E25fD7C8AE7CADDC6F71b461b79CD4ddcFa3/StakedTokenV3/lib/stk-no-cooldown/src/interfaces/IStakedTokenV3.sol
diff --git a/src/etherscan/mainnet_0x9921c8cea5815364d0f8350e6cbe9042A92448c9/StakedTokenV3/src/interfaces/ITransferHook.sol b/src/etherscan/sepolia_0xd1B3E25fD7C8AE7CADDC6F71b461b79CD4ddcFa3/StakedTokenV3/lib/stk-no-cooldown/src/interfaces/ITransferHook.sol
similarity index 100%
rename from src/etherscan/mainnet_0x9921c8cea5815364d0f8350e6cbe9042A92448c9/StakedTokenV3/src/interfaces/ITransferHook.sol
rename to src/etherscan/sepolia_0xd1B3E25fD7C8AE7CADDC6F71b461b79CD4ddcFa3/StakedTokenV3/lib/stk-no-cooldown/src/interfaces/ITransferHook.sol
diff --git a/src/etherscan/mainnet_0x9921c8cea5815364d0f8350e6cbe9042A92448c9/StakedTokenV3/src/lib/Address.sol b/src/etherscan/sepolia_0xd1B3E25fD7C8AE7CADDC6F71b461b79CD4ddcFa3/StakedTokenV3/lib/stk-no-cooldown/src/lib/Address.sol
similarity index 100%
rename from src/etherscan/mainnet_0x9921c8cea5815364d0f8350e6cbe9042A92448c9/StakedTokenV3/src/lib/Address.sol
rename to src/etherscan/sepolia_0xd1B3E25fD7C8AE7CADDC6F71b461b79CD4ddcFa3/StakedTokenV3/lib/stk-no-cooldown/src/lib/Address.sol
diff --git a/src/etherscan/mainnet_0x9921c8cea5815364d0f8350e6cbe9042A92448c9/StakedTokenV3/src/lib/Context.sol b/src/etherscan/sepolia_0xd1B3E25fD7C8AE7CADDC6F71b461b79CD4ddcFa3/StakedTokenV3/lib/stk-no-cooldown/src/lib/Context.sol
similarity index 100%
rename from src/etherscan/mainnet_0x9921c8cea5815364d0f8350e6cbe9042A92448c9/StakedTokenV3/src/lib/Context.sol
rename to src/etherscan/sepolia_0xd1B3E25fD7C8AE7CADDC6F71b461b79CD4ddcFa3/StakedTokenV3/lib/stk-no-cooldown/src/lib/Context.sol
diff --git a/src/etherscan/mainnet_0x9921c8cea5815364d0f8350e6cbe9042A92448c9/StakedTokenV3/src/lib/DistributionTypes.sol b/src/etherscan/sepolia_0xd1B3E25fD7C8AE7CADDC6F71b461b79CD4ddcFa3/StakedTokenV3/lib/stk-no-cooldown/src/lib/DistributionTypes.sol
similarity index 100%
rename from src/etherscan/mainnet_0x9921c8cea5815364d0f8350e6cbe9042A92448c9/StakedTokenV3/src/lib/DistributionTypes.sol
rename to src/etherscan/sepolia_0xd1B3E25fD7C8AE7CADDC6F71b461b79CD4ddcFa3/StakedTokenV3/lib/stk-no-cooldown/src/lib/DistributionTypes.sol
diff --git a/src/etherscan/mainnet_0x9921c8cea5815364d0f8350e6cbe9042A92448c9/StakedTokenV3/src/lib/ERC20.sol b/src/etherscan/sepolia_0xd1B3E25fD7C8AE7CADDC6F71b461b79CD4ddcFa3/StakedTokenV3/lib/stk-no-cooldown/src/lib/ERC20.sol
similarity index 100%
rename from src/etherscan/mainnet_0x9921c8cea5815364d0f8350e6cbe9042A92448c9/StakedTokenV3/src/lib/ERC20.sol
rename to src/etherscan/sepolia_0xd1B3E25fD7C8AE7CADDC6F71b461b79CD4ddcFa3/StakedTokenV3/lib/stk-no-cooldown/src/lib/ERC20.sol
diff --git a/src/etherscan/mainnet_0x9921c8cea5815364d0f8350e6cbe9042A92448c9/StakedTokenV3/src/lib/GovernancePowerDelegationERC20.sol b/src/etherscan/sepolia_0xd1B3E25fD7C8AE7CADDC6F71b461b79CD4ddcFa3/StakedTokenV3/lib/stk-no-cooldown/src/lib/GovernancePowerDelegationERC20.sol
similarity index 100%
rename from src/etherscan/mainnet_0x9921c8cea5815364d0f8350e6cbe9042A92448c9/StakedTokenV3/src/lib/GovernancePowerDelegationERC20.sol
rename to src/etherscan/sepolia_0xd1B3E25fD7C8AE7CADDC6F71b461b79CD4ddcFa3/StakedTokenV3/lib/stk-no-cooldown/src/lib/GovernancePowerDelegationERC20.sol
diff --git a/src/etherscan/mainnet_0x9921c8cea5815364d0f8350e6cbe9042A92448c9/StakedTokenV3/src/lib/GovernancePowerWithSnapshot.sol b/src/etherscan/sepolia_0xd1B3E25fD7C8AE7CADDC6F71b461b79CD4ddcFa3/StakedTokenV3/lib/stk-no-cooldown/src/lib/GovernancePowerWithSnapshot.sol
similarity index 100%
rename from src/etherscan/mainnet_0x9921c8cea5815364d0f8350e6cbe9042A92448c9/StakedTokenV3/src/lib/GovernancePowerWithSnapshot.sol
rename to src/etherscan/sepolia_0xd1B3E25fD7C8AE7CADDC6F71b461b79CD4ddcFa3/StakedTokenV3/lib/stk-no-cooldown/src/lib/GovernancePowerWithSnapshot.sol
diff --git a/src/etherscan/mainnet_0x9921c8cea5815364d0f8350e6cbe9042A92448c9/StakedTokenV3/src/lib/PercentageMath.sol b/src/etherscan/sepolia_0xd1B3E25fD7C8AE7CADDC6F71b461b79CD4ddcFa3/StakedTokenV3/lib/stk-no-cooldown/src/lib/PercentageMath.sol
similarity index 100%
rename from src/etherscan/mainnet_0x9921c8cea5815364d0f8350e6cbe9042A92448c9/StakedTokenV3/src/lib/PercentageMath.sol
rename to src/etherscan/sepolia_0xd1B3E25fD7C8AE7CADDC6F71b461b79CD4ddcFa3/StakedTokenV3/lib/stk-no-cooldown/src/lib/PercentageMath.sol
diff --git a/src/etherscan/mainnet_0x9921c8cea5815364d0f8350e6cbe9042A92448c9/StakedTokenV3/src/lib/SafeCast.sol b/src/etherscan/sepolia_0xd1B3E25fD7C8AE7CADDC6F71b461b79CD4ddcFa3/StakedTokenV3/lib/stk-no-cooldown/src/lib/SafeCast.sol
similarity index 100%
rename from src/etherscan/mainnet_0x9921c8cea5815364d0f8350e6cbe9042A92448c9/StakedTokenV3/src/lib/SafeCast.sol
rename to src/etherscan/sepolia_0xd1B3E25fD7C8AE7CADDC6F71b461b79CD4ddcFa3/StakedTokenV3/lib/stk-no-cooldown/src/lib/SafeCast.sol
diff --git a/src/etherscan/mainnet_0x9921c8cea5815364d0f8350e6cbe9042A92448c9/StakedTokenV3/src/lib/SafeERC20.sol b/src/etherscan/sepolia_0xd1B3E25fD7C8AE7CADDC6F71b461b79CD4ddcFa3/StakedTokenV3/lib/stk-no-cooldown/src/lib/SafeERC20.sol
similarity index 100%
rename from src/etherscan/mainnet_0x9921c8cea5815364d0f8350e6cbe9042A92448c9/StakedTokenV3/src/lib/SafeERC20.sol
rename to src/etherscan/sepolia_0xd1B3E25fD7C8AE7CADDC6F71b461b79CD4ddcFa3/StakedTokenV3/lib/stk-no-cooldown/src/lib/SafeERC20.sol
diff --git a/src/etherscan/mainnet_0x9921c8cea5815364d0f8350e6cbe9042A92448c9/StakedTokenV3/src/utils/RoleManager.sol b/src/etherscan/sepolia_0xd1B3E25fD7C8AE7CADDC6F71b461b79CD4ddcFa3/StakedTokenV3/lib/stk-no-cooldown/src/utils/RoleManager.sol
similarity index 100%
rename from src/etherscan/mainnet_0x9921c8cea5815364d0f8350e6cbe9042A92448c9/StakedTokenV3/src/utils/RoleManager.sol
rename to src/etherscan/sepolia_0xd1B3E25fD7C8AE7CADDC6F71b461b79CD4ddcFa3/StakedTokenV3/lib/stk-no-cooldown/src/utils/RoleManager.sol
diff --git a/src/etherscan/mainnet_0x9921c8cea5815364d0f8350e6cbe9042A92448c9/StakedTokenV3/src/utils/VersionedInitializable.sol b/src/etherscan/sepolia_0xd1B3E25fD7C8AE7CADDC6F71b461b79CD4ddcFa3/StakedTokenV3/lib/stk-no-cooldown/src/utils/VersionedInitializable.sol
similarity index 100%
rename from src/etherscan/mainnet_0x9921c8cea5815364d0f8350e6cbe9042A92448c9/StakedTokenV3/src/utils/VersionedInitializable.sol
rename to src/etherscan/sepolia_0xd1B3E25fD7C8AE7CADDC6F71b461b79CD4ddcFa3/StakedTokenV3/lib/stk-no-cooldown/src/utils/VersionedInitializable.sol
```
