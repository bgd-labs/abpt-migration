# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env

# deps
update:; forge update

# Build & test
build  :; forge build --sizes
test   :; forge test -vvv

deploy-ledger :; forge script ${contract} --rpc-url ${chain} $(if ${dry},--sender 0x25F2226B597E8F9514B3F68F00f494cF4f286491 -vvvv,--broadcast --ledger --mnemonics foo --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER} --verify -vvvv)

# Utilities
download :; cast etherscan-source --chain ${chain} -d src/etherscan/${chain}_${address} ${address}
git-diff :
	@mkdir -p diffs
	@printf '%s\n%s\n%s\n' "\`\`\`diff" "$$(git diff --no-index --diff-algorithm=patience --ignore-space-at-eol ${before} ${after})" "\`\`\`" > diffs/${out}.md

deploy-impl-ledger :; make deploy-ledger contract=scripts/01_DeployStkAbptV2ImplTest.sol:DeployImpl chain=sepolia

diff-all :
# StakedTokenV3 - live
	make download chain=mainnet address=0x9921c8cea5815364d0f8350e6cbe9042A92448c9
# Demo deployment - next
	make download chain=sepolia address=0x70Bf6EC6Fca41a7d08dCBB9909985AC0A4510B5E
# Demo deploynebt - no-cooldown
	make download chain=sepolia address=0xd1B3E25fD7C8AE7CADDC6F71b461b79CD4ddcFa3
	npm run lint:fix
	make git-diff before=src/etherscan/mainnet_0x9921c8cea5815364d0f8350e6cbe9042A92448c9 after=src/etherscan/sepolia_0x70Bf6EC6Fca41a7d08dCBB9909985AC0A4510B5E out=NewVersionDiff
	make git-diff before=src/etherscan/mainnet_0x9921c8cea5815364d0f8350e6cbe9042A92448c9 after=src/etherscan/sepolia_0xd1B3E25fD7C8AE7CADDC6F71b461b79CD4ddcFa3 out=NoCooldownDiff

diff-snapshot :
	forge inspect src/etherscan/mainnet_0x9921c8cea5815364d0f8350e6cbe9042A92448c9/StakedTokenV3/src/contracts/StakedTokenV3.sol:StakedTokenV3 storage-layout --pretty > diffs/currentStakedToken.md
	forge inspect src/etherscan/sepolia_0x70Bf6EC6Fca41a7d08dCBB9909985AC0A4510B5E/StakedTokenV3/src/contracts/StakedTokenV3.sol:StakedTokenV3 storage-layout --pretty > diffs/newStakedToken.md
	forge inspect src/etherscan/sepolia_0xd1B3E25fD7C8AE7CADDC6F71b461b79CD4ddcFa3/StakedTokenV3/src/contracts/StakedTokenV3.sol:StakedTokenV3 storage-layout --pretty > diffs/zeroCooldownStakedToken.md
