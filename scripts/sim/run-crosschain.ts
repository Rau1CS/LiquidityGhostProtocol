import { execSync } from "child_process";
import path from "path";
const op = path.join(__dirname, "../../watcher/out/opportunities/example-crosschain.json");
execSync(`node ../../kettle-sim/bin/kettle run --op ${op} --dry-run`, { stdio: "inherit", env: { ...process.env, ENABLE_CROSSCHAIN: "true" } });
