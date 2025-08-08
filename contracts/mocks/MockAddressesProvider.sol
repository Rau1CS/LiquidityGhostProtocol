// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IPoolAddressesProvider} from "contracts/adapters/aave/IAaveV3.sol";

contract MockAddressesProvider is IPoolAddressesProvider {
    address private pool;

    constructor(address _pool) {
        pool = _pool;
    }

    function getPool() external view override returns (address) {
        return pool;
    }

    function setPool(address p) external {
        pool = p;
    }
}
