// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import { IDeployManager } from "../DeployManager/IDeployManager.sol";
import { IUtilityContract } from "../UtilityContract/IUtilityContract.sol";

abstract contract AbstractUtilityContract is IUtilityContract, ERC165{

    /// @notice Address of DeployManager that deployed this contract
    address public deployManager;

    /// @notice Tracks whether the contract has been initialized
    bool public initialized;

     modifier notInitialized() {
        require(!initialized, AlreadyInitialized());
        _;
    }

    /// @inheritdoc IUtilityContract
    function initialize(bytes memory _initData) external virtual returns (bool) {
        deployManager = abi.decode(_initData, (address));
        setDeployManager(deployManager);
        return true;
    }

    /// @notice Internal function for setting deployManager
    /// @param _deployManager DeployManager address
    function setDeployManager (address _deployManager) internal virtual {
        if (!validateDeployManager(_deployManager)) {
            revert FailedToValidateDeployManager();
        }
        deployManager = _deployManager;
    }

    /// @notice Checks if the _deployManager is valid DeployManager
    /// @param _deployManager DeployManager address
    /// @return True if valid
    /// @dev Validates _deployManager is not zero address and supports IDeployManager interface
    function validateDeployManager(address _deployManager) internal view returns (bool) {
        if(_deployManager == address(0)) {
            revert DeployManagerCannotBeZero();
        }

        bytes4 interfaceId = type(IDeployManager).interfaceId;

        if (!IDeployManager(_deployManager).supportsInterface(interfaceId)) {
            revert NotDeployManager();
        }

        return true;
    }

    /// @inheritdoc IUtilityContract
     function getDeployManager() external view virtual override returns (address) {
        return deployManager;
     }

    /// @inheritdoc ERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool){
        return
            interfaceId == type(IUtilityContract).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}