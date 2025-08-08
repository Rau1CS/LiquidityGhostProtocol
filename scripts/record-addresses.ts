import fs from "fs";
import path from "path";

// Usage: ts-node scripts/record-addresses.ts path/to/deploy.json
// deploy.json format: { "chainId": 11155111, "LGPCore": "0x...", ... }

const [,, file] = process.argv;
if (!file) {
  console.error("usage: record-addresses <deploy.json>");
  process.exit(1);
}

const update = JSON.parse(fs.readFileSync(file, "utf8"));
const chainId = update.chainId || update.chain_id || Object.keys(update)[0];
const addressesPath = path.join(__dirname, "addresses.json");
const current = fs.existsSync(addressesPath) ? JSON.parse(fs.readFileSync(addressesPath, "utf8")) : {};
current[chainId] = { ...(current[chainId] || {}), ...update };
fs.writeFileSync(addressesPath, JSON.stringify(current, null, 2));
console.log(`recorded addresses for chain ${chainId}`);
