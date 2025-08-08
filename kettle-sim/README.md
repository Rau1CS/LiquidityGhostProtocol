# Kettle Simulation Engine

Local SUAVE-like executor for testing liquidation opportunities.

## Usage

```
npm install
cp .env.example .env
node bin/kettle run --op ../watcher/out/opportunities/example-samechain.json --dry-run
node bin/kettle run --op ../watcher/out/opportunities/example-crosschain.json --dry-run
```

Dry run prints the planned route and simulated settlement hash.
