// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { IDeployManager } from "../DeployManager/IDeployManager.sol";
import { IUtilityContract } from "../UtilityContract/IUtilityContract.sol";

abstract contract AbstractUtilityContract {

    address public deployManager;

    function initialize(bytes memory _initData) external virtual returns (bool) {
        deployManager = abi.decode(_initData, (address));
        return true;
    }

}