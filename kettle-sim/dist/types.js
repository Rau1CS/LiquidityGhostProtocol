import { z } from "zod";
export const Opportunity = z.object({
  id: z.string(),
  user: z.string(),
  market: z.string(),
  srcChainId: z.number(),
  dstChainId: z.number(),
  debtAsset: z.string(),
  debtAmount: z.string(),
  collateralAsset: z.string(),
  deadline: z.number(),
  minProfitUsd: z.number(),
  expectCrossChain: z.boolean().default(false)
});
export function makePlan(cross, steps) { return { crossChain: cross, steps }; }
