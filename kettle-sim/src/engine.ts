import { Opportunity, Plan } from "./types.js";

function nowSeconds(): number {
  return Math.floor(Date.now() / 1000);
}

export function planOpportunity(opp: Opportunity): Plan {
  const enableCross = process.env.ENABLE_CROSSCHAIN === "true";
  const minProfit = Number(process.env.MIN_PROFIT_USD || 0);
  if (opp.deadline <= nowSeconds()) throw new Error("deadline passed");
  if (opp.minProfitUsd < minProfit) throw new Error("minProfit too low");
  const cross = enableCross && opp.expectCrossChain && opp.srcChainId !== opp.dstChainId;
  const steps: string[] = [];
  if (cross) {
    steps.push("flashloan-src", "bridge-send", "bridge-receive", "flashloan-dst", "liquidate", "settle");
  } else {
    steps.push("flashloan", "liquidate", "settle");
  }
  return { crossChain: cross, steps };
}
