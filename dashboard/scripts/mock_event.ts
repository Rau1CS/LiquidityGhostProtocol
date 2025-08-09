import dotenv from 'dotenv';
import { promises as fs } from 'fs';
import { z } from 'zod';
import { init, handleRescue, createMockRescue, writeFiles } from '../src/collector';

dotenv.config();

const envSchema = z.object({
  SAVE_DIR: z.string().default('./public'),
  WINDOW_MINUTES: z.coerce.number().default(60),
  ETH_PRICE_USD: z.coerce.number().default(3500),
});

async function main() {
  const env = envSchema.parse(process.env);
  await fs.mkdir(env.SAVE_DIR, { recursive: true });
  init(env);
  handleRescue(createMockRescue());
  await writeFiles();
}

main();
