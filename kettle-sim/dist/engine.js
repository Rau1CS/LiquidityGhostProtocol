import { Opportunity } from "./types.js";
function nowSeconds() { return Math.floor(Date.now() / 1000); }
export function planOpportunity(opp) {
  const enableCross = process.env.ENABLE_CROSSCHAIN === "true";
  const minProfit = Number(process.env.MIN_PROFIT_USD || 0);
  if (opp.deadline <= nowSeconds()) throw new Error("deadline passed");
  if (opp.minProfitUsd < minProfit) throw new Error("minProfit too low");
  const cross = enableCross && opp.expectCrossChain && opp.srcChainId !== opp.dstChainId;
  const steps = cross ? ["flashloan-src", "bridge-send", "bridge-receive", "flashloan-dst", "liquidate", "settle"] : ["flashloan", "liquidate", "settle"];
  return { crossChain: cross, steps };
}
