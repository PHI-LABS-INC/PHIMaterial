// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import { Script } from "forge-std/Script.sol";

abstract contract BaseScript is Script {
    /// @dev Needed for the deterministic deployments.
    bytes32 internal constant ZERO_SALT = bytes32(0);

    /// @dev The address of the contract deployer.
    address internal deployer;

    /// @dev Used to derive the deployer's address.
    string internal mnemonic;

    constructor() {
        string memory _mnemonic = vm.envString("MNEMONIC");
        mnemonic = vm.envOr("MNEMONIC", _mnemonic);
        (deployer,) = deriveRememberKey({ mnemonic: mnemonic, index: 0 });
    }

    modifier broadcaster() {
        vm.startBroadcast(deployer);
        _;
        vm.stopBroadcast();
    }
}
