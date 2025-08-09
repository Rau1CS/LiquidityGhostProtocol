import { BigNumber, utils } from 'ethers';
import { promises as fs } from 'fs';
import path from 'path';

export interface EnvConfig {
  SAVE_DIR: string;
  WINDOW_MINUTES: number;
  ETH_PRICE_USD: number;
}

export interface Rescue {
  rescueId: string;
  kettle: string;
  market: string;
  amount: BigNumber;
  timestamp: number;
}

let env: EnvConfig;
let events: Rescue[] = [];

export function init(config: EnvConfig) {
  env = config;
}

export function handleRescue(rescue: Rescue) {
  events.push(rescue);
}

export function createMockRescue(): Rescue {
  const randomAddress = () =>
    '0x' + Array.from({ length: 40 }, () => Math.floor(Math.random() * 16).toString(16)).join('');
  return {
    rescueId: utils.hexlify(utils.randomBytes(32)),
    kettle: randomAddress(),
    market: randomAddress(),
    amount: utils.parseEther((Math.random() * 0.1 + 0.01).toFixed(4)),
    timestamp: Date.now(),
  };
}

function summarize() {
  const now = Date.now();
  const windowMs = env.WINDOW_MINUTES * 60 * 1000;
  events = events.filter((e) => e.timestamp >= now - windowMs);

  const rescues = events.length;
  let savedUsd = 0;
  const marketCounts: Record<string, number> = {};
  const kettles: Record<string, { landed: number; est_bot_earnings_usd: number; holdback_pending_usd: number; last_seen: string }>
    = {};

  for (const e of events) {
    const eth = Number(utils.formatUnits(e.amount, 18));
    const usd = eth * env.ETH_PRICE_USD;
    savedUsd += usd;

    marketCounts[e.market] = (marketCounts[e.market] || 0) + 1;

    if (!kettles[e.kettle]) {
      kettles[e.kettle] = {
        landed: 0,
        est_bot_earnings_usd: 0,
        holdback_pending_usd: 0,
        last_seen: new Date(e.timestamp).toISOString(),
      };
    }
    const k = kettles[e.kettle];
    k.landed += 1;
    k.est_bot_earnings_usd += usd;
    k.last_seen = new Date(e.timestamp).toISOString();
  }

  const top_markets = Object.entries(marketCounts)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 5)
    .map(([addr]) => addr);

  const savings = {
    version: 1,
    window: `${env.WINDOW_MINUTES / 60}h`,
    rescues,
    saved_usd: savedUsd,
    user_payout_usd: savedUsd,
    protocol_revenue_usd: 0,
    top_markets,
    last_updated: new Date(now).toISOString(),
  };

  const leaderboard = {
    version: 1,
    kettles,
    last_updated: new Date(now).toISOString(),
  };

  return { savings, leaderboard };
}

export async function writeFiles() {
  if (!env) throw new Error('collector not initialized');
  const { savings, leaderboard } = summarize();
  await fs.writeFile(path.join(env.SAVE_DIR, 'savings.json'), JSON.stringify(savings, null, 2));
  await fs.writeFile(path.join(env.SAVE_DIR, 'leaderboard.json'), JSON.stringify(leaderboard, null, 2));
}
