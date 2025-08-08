import { Command } from "commander";
import { readFileSync } from "fs";
import { Opportunity } from "./types.js";
import { planOpportunity } from "./engine.js";
import { execute } from "./executor.js";
import dotenv from "dotenv";

dotenv.config();

const program = new Command();

program
  .command("run")
  .requiredOption("--op <path>", "path to opportunity json")
  .option("--dry-run", "simulate without transactions")
  .action(async (opts) => {
    const raw = JSON.parse(readFileSync(opts.op, "utf8"));
    const opp = Opportunity.parse(raw);
    const plan = planOpportunity(opp);
    await execute(opp, plan, { dryRun: opts.dryRun });
  });

program.parse();
