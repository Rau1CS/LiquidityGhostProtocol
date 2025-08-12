#!/usr/bin/env bash
set -e
for T in "EarningsEscrow" "LGPCore" "MockLendingMarket" "MockERC20" "BridgeAdapterMock"; do
  PATH_HINT=$(rg -l "contract $T" contracts | head -n1)
  forge inspect "$PATH_HINT:$T" abi | jq '.[] | select(.type=="constructor")'
done
