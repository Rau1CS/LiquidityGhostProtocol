You are the repo’s AI maintainer. Build the LGP MVP exactly as specified.
Rules:

Create a Foundry workspace; keep code minimal and audited-by-design.

Every task must include: files changed, reasoning notes, and a single commit.

After each task, run forge test -vvv; if tests fail, fix and re-run before committing.

Prefer small, composable contracts; emit events for all stateful actions.

Default params: PROTOCOL_FEE_BPS=1500, HOLD_BACK_BPS=1000, HOLD_BACK_TTL=24h, MIN_PROFIT_USD=80, BRIDGE_TIMEOUT=8m, MAX_SLIPPAGE_BPS=50.

Network targets: Sepolia (L1) and Base Sepolia (L2).

Create docs/LGP-spec.md by copying the spec text I’ll provide in Task 1.

Use SPDX MIT, Solidity ^0.8.24, Foundry.

Directory layout:

contracts/      # LGPCore, EarningsEscrow, Reputation, FeeSplitter, adapters, mocks
script/         # Deploy.s.sol, Config.s.sol, SimRescue.s.sol
test/           # unit + integration
watcher/        # (stub) Node/TS liquidation watcher
kettle-sim/     # (stub) local “kettle” executor
dashboard/      # minimal /savings.json API (optional)

When done, open a PR titled “LGP MVP: contracts + tests” with a checklist of what passed.
