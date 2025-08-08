import fs from "fs";
import path from "path";

export interface AddressRecord {
  LGPCore: string;
  EarningsEscrow: string;
  Reputation: string;
  FlashloanAdapter: string;
  BridgeAdapter: string;
  MockLendingMarket: string;
  Treasury: string;
}

export type AddressBook = Record<number, AddressRecord>;

export function loadAddresses(file?: string): AddressBook {
  const p = file || process.env.ADDRESSES_JSON || path.join(__dirname, "../../scripts/addresses.json");
  const data = fs.readFileSync(p, "utf8");
  return JSON.parse(data);
}
