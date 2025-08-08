import { z } from "zod";
export const Opportunity = z.object({
  id: z.string(),
  user: z.string(),
  market: z.string(),
  srcChainId: z.number(),   // e.g., 8453 (Base)
  dstChainId: z.number(),   // e.g., 1 (Ethereum)
  debtAsset: z.string(),
  debtAmount: z.string(),   // wei
  collateralAsset: z.string(),
  deadline: z.number(),     // unix sec
  minProfitUsd: z.number(), // e.g., 80
  expectCrossChain: z.boolean().default(false)
});
export type Opportunity = z.infer<typeof Opportunity>;

export interface Plan {
  crossChain: boolean;
  steps: string[];
}
