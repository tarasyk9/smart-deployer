// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IDeployManager} from "src/DeployManager/IDeployManager.sol";

contract MockDeployManager is IDeployManager {
    bool public supportsIface = true;

    function setSupports(bool v) external {
        supportsIface = v;
    }

    function supportsInterface(bytes4 interfaceId) external view override returns (bool) {
        return supportsIface && interfaceId == type(IDeployManager).interfaceId;
    }

    function deploy(address, bytes calldata) external payable override returns (address) {
        return address(0);
    }

    function addNewContract(address, uint256, bool) external override {}
    function updateFee(address, uint256) external override {}
    function deactivateContract(address) external override {}
    function activateContract(address) external override {}
}