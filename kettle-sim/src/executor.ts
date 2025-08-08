import { JsonRpcProvider } from "ethers";
import { keccak256, toUtf8Bytes } from "ethers";
import { Opportunity, Plan } from "./types.js";
import { loadAddresses } from "./addresses.js";
import dotenv from "dotenv";

dotenv.config();

function providerFor(chainId: number): JsonRpcProvider {
  const rpcL1 = process.env.RPC_L1 || "";
  const rpcL2 = process.env.RPC_L2 || "";
  // naive: assume dst chain uses RPC_L1, src uses RPC_L2 if different
  if (chainId === Number(process.env.L1_CHAIN_ID || 11155111)) return new JsonRpcProvider(rpcL1);
  return new JsonRpcProvider(rpcL2);
}

export async function execute(opp: Opportunity, plan: Plan, opts: { dryRun?: boolean }) {
  const addrs = loadAddresses();
  const kettleKey = process.env.KETTLE_KEY || "0x";
  if (opts.dryRun) {
    console.log("[dry-run] executing plan:", plan.steps.join(" -> "));
  }
  if (plan.crossChain) {
    console.log("flash loan on src chain", opp.srcChainId);
    console.log("bridge send to", opp.dstChainId);
    console.log("waiting for bridge ...");
    console.log("receive on dst chain", opp.dstChainId);
    console.log("flash loan on dst chain", opp.dstChainId);
  } else {
    console.log("flash loan on chain", opp.srcChainId);
  }
  console.log("liquidate on market", opp.market);
  console.log("settle via LGPCore", addrs[opp.dstChainId]?.LGPCore || "unknown");
  const receiptHash = keccak256(toUtf8Bytes(opp.id + kettleKey));
  console.log("simulated receipt hash", receiptHash);
  if (!opts.dryRun) {
    const provider = providerFor(opp.dstChainId);
    await provider.getBlockNumber(); // touch provider
  }
}
