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

// simple bridge helper used in simulations/tests
export async function bridgeSend(
  adapterSrc: any,
  adapterDst: any,
  token: string,
  amount: bigint,
  dstChainId: number,
  memo: string,
  payload: string
): Promise<string> {
  const latency = Number(process.env.BRIDGE_LATENCY_SEC || 0);
  const timeout = Number(process.env.BRIDGE_TIMEOUT_SEC || 0);
  const guid: string = await adapterSrc.send(token, amount, dstChainId, memo);
  if (latency > 0) {
    await new Promise((resolve) => setTimeout(resolve, latency * 1000));
  }
  if (timeout > 0 && latency > timeout) {
    throw new Error("bridge timeout");
  }
  await adapterDst.deliver(guid, payload);
  return guid;
}
