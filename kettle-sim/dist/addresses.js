import fs from "fs";
import path from "path";
export function loadAddresses(file) {
  const p = file || process.env.ADDRESSES_JSON || path.join(path.dirname(new URL(import.meta.url).pathname), "../../scripts/addresses.json");
  const data = fs.readFileSync(p, "utf8");
  return JSON.parse(data);
}
