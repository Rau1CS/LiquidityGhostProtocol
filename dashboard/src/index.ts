import dotenv from 'dotenv';
import express from 'express';
import pino from 'pino';
import path from 'path';
import { promises as fs } from 'fs';
import { ethers } from 'ethers';
import { z } from 'zod';
import abi from './abi/LGPCore.json';
import { init, handleRescue, createMockRescue, writeFiles } from './collector';

dotenv.config();

const envSchema = z.object({
  L1_RPC_WS: z.string().optional(),
  L1_RPC_URL: z.string().optional(),
  LGP_CORE: z.string().default('0x0000000000000000000000000000000000000000'),
  EARNINGS_ESCROW: z.string().default('0x0000000000000000000000000000000000000000'),
  REPUTATION: z.string().default('0x0000000000000000000000000000000000000000'),
  TREASURY: z.string().default('0x0000000000000000000000000000000000000000'),
  PORT: z.coerce.number().default(8787),
  SAVE_DIR: z.string().default('./public'),
  WINDOW_MINUTES: z.coerce.number().default(60),
  ETH_PRICE_USD: z.coerce.number().default(3500),
  MOCK_MODE: z.preprocess((v) => v === 'true', z.boolean()).default(false),
  MOCK_INTERVAL_MS: z.coerce.number().default(5000),
});

const logger = pino();

async function main() {
  const env = envSchema.parse(process.env);
  await fs.mkdir(env.SAVE_DIR, { recursive: true });

  init({ SAVE_DIR: env.SAVE_DIR, WINDOW_MINUTES: env.WINDOW_MINUTES, ETH_PRICE_USD: env.ETH_PRICE_USD });

  if (env.MOCK_MODE) {
    setInterval(() => {
      const evt = createMockRescue();
      handleRescue(evt);
      logger.info({ rescueId: evt.rescueId }, 'mock rescue');
    }, env.MOCK_INTERVAL_MS);
  } else {
    let provider: ethers.providers.Provider | null = null;
    if (env.L1_RPC_WS) provider = new ethers.providers.WebSocketProvider(env.L1_RPC_WS);
    else if (env.L1_RPC_URL) provider = new ethers.providers.JsonRpcProvider(env.L1_RPC_URL);

    if (provider) {
      const contract = new ethers.Contract(env.LGP_CORE, abi, provider);
      contract.on('RescueExecuted', (rescueId, kettle, market, amount) => {
        handleRescue({ rescueId, kettle, market, amount, timestamp: Date.now() });
        logger.info({ rescueId, kettle, market }, 'RescueExecuted');
      });
    } else {
      logger.warn('No provider configured; enable MOCK_MODE to generate events');
    }
  }

  setInterval(() => {
    writeFiles().catch((err) => logger.error(err, 'writeFiles'));
  }, 5000);

  const app = express();
  app.get('/.well-known/savings.json', (req, res) =>
    res.sendFile(path.resolve(env.SAVE_DIR, 'savings.json'))
  );
  app.get('/leaderboard.json', (req, res) =>
    res.sendFile(path.resolve(env.SAVE_DIR, 'leaderboard.json'))
  );

  app.listen(env.PORT, () => logger.info(`listening on ${env.PORT}`));
}

main().catch((err) => logger.error(err));

export { handleRescue, createMockRescue, writeFiles };
