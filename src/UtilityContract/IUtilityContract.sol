// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/interfaces/IERC165.sol";

/// @title IUtilityContract - Interface for utility contracts
/// @notice This interface defines the functions and events for utility contracts
/// @dev Utility contracts should implement this interface to be compatible with the DeployManager
interface IUtilityContract is IERC165 {
    // ------------------------------------------------------------------------
    // Errors
    // ------------------------------------------------------------------------

    /// @dev Reverts if the deploy manager is not set or is invalid
    error DeployManagerCannotBeZero();

    /// @dev Reverts if coller is not DeployManager
    error NotDeployManager();

    /// @dev Reverts if DeployManager validation failed throw validateDeployManager()
    error FailedToValidateDeployManager();

    /// @dev Reverts if contract is already initialized
    error AlreadyInitialized();
    // ------------------------------------------------------------------------
    // Functions
    // ------------------------------------------------------------------------

    /// @notice Initializes the utility contract with the provided data
    /// @param _initData The initialization data for the utility contract
    /// @return True if the initialization was successful
    /// @dev This function should be called by the DeployManager after deploying the contract
    function initialize(bytes memory _initData) external returns (bool);

    /// @notice Shows DeployManager used for deployment of current contract
    /// @return address of deployManager
    function getDeployManager() external view returns (address);
}
